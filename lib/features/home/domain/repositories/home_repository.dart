import 'package:beltech/features/home/domain/entities/home_overview.dart';

abstract class HomeRepository {
  Stream<HomeOverview> watchOverview();
}
