import 'runtime_env_stub.dart' if (dart.library.io) 'runtime_env_io.dart'
    as runtime_env;

bool hasRuntimeEnv(String key) => runtime_env.hasRuntimeEnv(key);
