#!/usr/bin/env -S dart run

import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path_helper;
import 'package:xml/xml.dart';

void main(List<String> args) {
  // Parse arguments
  if (args.length != 1) {
    throw "Usage: bump_version.dart <new semVar version>";
  }
  final newVersion = args[0];

  // Determine original version number
  final baseDir = path_helper.joinAll(path_helper.split(Platform.script.path).slice2(0, -2));
  final pubspec = File(path_helper.join(baseDir, "pubspec.yaml"));
  final versionMatcher = RegExp(r'^version: ([\d\.]+)\+(\d+)\s*$', multiLine: true);
  final versionMatch = versionMatcher.firstMatch(pubspec.readAsStringSync())!;
  final oldVersion = versionMatch.group(1)!;
  final oldBuildNum = versionMatch.group(2)!;
  final newBuildNum = (int.parse(oldBuildNum) + 1).toString();
  validateVersion(oldVersion, newVersion);

  // Extract new changelog
  final changeLogDir = path_helper.join(baseDir, "fastlane", "metadata", "android");
  final changelogFile = File(path_helper.join(changeLogDir, "en-US", "changelogs", "$newBuildNum.txt"));
  if (!changelogFile.existsSync()) {
    throw "Please add the new changelog to ${changelogFile.path}";
  }
  final changelog = changelogFile.readAsStringSync();
  final changelogParagraphs = changelog.split("\n\n").map((x) => x.trim()).toList();
  final changelogThanks = changelogParagraphs[changelogParagraphs.length - 1];
  if (changelogThanks != "Thank you for using Finamp!") {
    throw "Unexpected ending paragraph [[$changelogThanks]]";
  }
  for (final par in changelogParagraphs) {
    if (par.startsWith("<") && !par.endsWith(">")) {
      throw "Unexpected formating on paragraph [[$par]]";
    }
  }

  // Create other language changelogs
  for (final lang in Directory(changeLogDir).listSync()) {
    if (path_helper.split(lang.path).last == "en-US") {
      continue;
    }
    final langChange = path_helper.join(lang.path, "changelogs", "$newBuildNum.txt");
    if (File(langChange).existsSync()) {
      print("File $langChange already exists - Skipping.");
      continue;
    }
    final oldChange = path_helper.join(lang.path, "changelogs", "$oldBuildNum.txt");
    if (!File(oldChange).existsSync()) {
      print("Old changelog missing for $langChange - Skipping.");
      continue;
    }
    final translatedThanks = changelogFile.readAsStringSync().split("\n\n").map((x) => x.trim()).last;
    final writer = File(langChange).openSync(mode: FileMode.writeOnly);
    for (int i = 0; i < changelogParagraphs.length - 1; i++) {
      writer.writeStringSync(changelogParagraphs[i]);
      writer.writeStringSync("\n\n");
    }
    writer.writeStringSync(translatedThanks);
    writer.closeSync();
    try {
      Process.runSync("git", ["add", langChange]);
    } catch (_) {
      print("Could not add $langChange to git - Ignoring.");
    }
  }

  // Add paragraph to xml
  final flathubPath = path_helper.join(baseDir, "assets", "com.unicornsonlsd.finamp.metainfo.xml");
  final manifest = XmlDocument.parse(File(flathubPath).readAsStringSync());
  if (manifest.findAllElements("release").where((x) => x.getAttribute("version") == newVersion).isNotEmpty) {
    print("Version $newVersion already present in metainfo.xml - skipping.");
  } else {
    final releases = manifest.findAllElements("releases").first;
    final builder = XmlBuilder();
    builder.element(
      "release",
      nest: () {
        builder.attribute("version", newVersion);
        final now = DateTime.now();
        builder.attribute("date", "${now.year}-${now.month}-${now.day}");
        builder.element(
          "url",
          nest: () {
            builder.attribute("type", "details");
            builder.text("https://github.com/finamp-app/finamp/releases/$newVersion");
          },
        );
        builder.element(
          "description",
          nest: () {
            for (final par in changelogParagraphs) {
              if (par.startsWith("<")) {
                builder.xml(par);
              } else {
                builder.element(
                  "p",
                  nest: () {
                    builder.text(par);
                  },
                );
              }
            }
          },
        );
      },
    );
    releases.children.insert(0, builder.buildFragment());
    final writer = File(flathubPath).openSync(mode: FileMode.writeOnly);
    writer.writeStringSync(manifest.toXmlString(pretty: true, indent: '  '));
    writer.closeSync();
  }

  // Update pubspec
  var pubContents = pubspec.readAsStringSync();
  pubContents = pubContents.replaceAll(versionMatcher, "version: $newVersion+$newBuildNum");
  final msixMatcher = RegExp(r'^(\s*)msix_version: [\d\.]+\s*$', multiLine: true);
  final msixMatch = msixMatcher.firstMatch(pubContents);
  pubContents = pubContents.replaceFirst(msixMatcher, "${msixMatch!.group(1)!}msix_version: $newVersion.0");
  final writer = pubspec.openSync(mode: FileMode.writeOnly);
  writer.writeStringSync(pubContents);
  writer.closeSync();
}

void validateVersion(String oldVer, String newVer) {
  print("Bumping version from $oldVer to $newVer");
  List<int> oldSplit;
  List<int> newSplit;
  try {
    oldSplit = oldVer.split(r'.').map((x) => int.parse(x)).toList();
    newSplit = newVer.split(r'.').map((x) => int.parse(x)).toList();
  } catch (_) {
    throw "Invalid version code";
  }
  if (oldSplit.length != 3 || newSplit.length != 3) {
    throw "Invalid version code";
  }
  int bumped = 0;
  for (int i = 0; i < 3; i++) {
    if (oldSplit[i] == newSplit[i]) {
      continue;
    } else if (oldSplit[i] + 1 == newSplit[i]) {
      bumped++;
    } else {
      throw "Invalid version code";
    }
  }
  if (bumped != 1) {
    throw "Invalid version code";
  }
}

extension NegSlice<T> on List<T> {
  ListSlice<T> slice2(int start, int? end) {
    if (end != null && end < 0) {
      end += length;
    }
    return slice(start, end);
  }
}
