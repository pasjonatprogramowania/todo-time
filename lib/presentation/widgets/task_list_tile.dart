import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart';

class TaskListTile extends ConsumerWidget {
  final TaskEntity task;

  const TaskListTile({super.key, required this.task});

  String _formatTimeAward(Duration duration) {
    if (duration.inMinutes < 60) {
      return "+${duration.inMinutes}m";
    } else {
      return "+${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color? textColor = task.isCompleted
        ? Theme.of(context).hintColor
        : null; // Default color if not completed
    final Color? completedIconColor = task.isCompleted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).hintColor.withOpacity(0.7);

    return Card(
      elevation: task.isCompleted ? 0.5 : 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: task.isCompleted
          ? (isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200.withOpacity(0.7))
          : Theme.of(context).cardColor,
      child: InkWell(
        onTap: () {
          context.goNamed('task_form', extra: task); // Navigate to edit task
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: completedIconColor,
                  size: 28,
                ),
                onPressed: () async {
                  try {
                    await ref.read(toggleTaskStatusUseCaseProvider).call(task.id);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update task: ${e.toString()}')),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: Theme.of(context).hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: task.isCompleted ? Theme.of(context).hintColor.withOpacity(0.8) : Theme.of(context).hintColor,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: Theme.of(context).hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Due: ${DateFormat.yMd().add_jm().format(task.dueDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: task.isCompleted ? Theme.of(context).hintColor.withOpacity(0.7) : Theme.of(context).hintColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? Theme.of(context).disabledColor.withOpacity(0.2)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatTimeAward(task.timeAward),
                      style: TextStyle(
                        color: task.isCompleted
                            ? Theme.of(context).hintColor
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.category.toString().split('.').last.replaceAllMapped(
                        RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trimLeft(), // Format category name
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4), // For a little padding before the edge of the card
            ],
          ),
        ),
      ),
    );
  }
}
