import 'dart:io';

bool hasRuntimeEnv(String key) => Platform.environment.containsKey(key);
