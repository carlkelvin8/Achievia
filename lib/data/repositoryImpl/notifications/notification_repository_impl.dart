import 'package:achievia/data/data_source/notifications/notification_remote_datasource.dart';
import 'package:achievia/domain/entities/widgets/notification_entity.dart';
import 'package:achievia/domain/repository/notifications/notification_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource datasource;

  NotificationRepositoryImpl(this.datasource);

  @override
  Future<List<NotificationEntity>> getNotifications() async =>
      (await datasource.getNotifications())
          .map((item) => item.toEntity())
          .toList();

  @override
  Future<void> markRead(String id) => datasource.markRead(id);

  @override
  Future<void> markAllRead() => datasource.markAllRead();

  @override
  Future<void> delete(String id) => datasource.delete(id);
}
