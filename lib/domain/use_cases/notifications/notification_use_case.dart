import 'package:achievia/data/repositoryImpl/notifications/notification_repository_impl.dart';
import 'package:achievia/domain/entities/widgets/notification_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class NotificationUseCase {
  final NotificationRepositoryImpl repository;

  NotificationUseCase(this.repository);

  Future<List<NotificationEntity>> getNotifications() =>
      repository.getNotifications();
  Future<void> markRead(String id) => repository.markRead(id);
  Future<void> markAllRead() => repository.markAllRead();
  Future<void> delete(String id) => repository.delete(id);
}
