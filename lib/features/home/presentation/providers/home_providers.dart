import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeOverviewProvider = StreamProvider<HomeOverview>(
  (ref) => ref.watch(homeRepositoryProvider).watchOverview(),
);
