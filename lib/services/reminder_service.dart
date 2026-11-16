import 'dart:io';

import 'package:flutter/services.dart';

import '../models/checklist_project.dart';

class ReminderService {
  static const channelName = 'checklist/reminders';
  static const _channel = MethodChannel(channelName);

  Future<void> sync(List<ChecklistProject> projects) async {
    if (!Platform.isAndroid) return;
    final reminders = projects
        .where((project) => project.reminderAt != null)
        .map(
          (project) => <String, Object>{
            'id': project.id,
            'title': project.name,
            'timeMillis': project.reminderAt!.millisecondsSinceEpoch,
          },
        )
        .toList();
    await _channel.invokeMethod<void>('sync', reminders);
  }
}
