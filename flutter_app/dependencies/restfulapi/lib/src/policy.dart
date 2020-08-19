/// 策略属性访问类（只读）
abstract class PolicyContextView {
  operator [](String key);
  V getPolicy<V>(String key);
  Map<String, dynamic> getAll();
}

/// 策略属性上下文
/// 其中策略的值必须为基本数据及容器类型
class PolicyContext implements PolicyContextView {
  final Map<String, dynamic> _policyMap;
  PolicyContext([PolicyContextView src])
      : _policyMap = src?.getAll() ?? <String, dynamic>{};

  @override
  V getPolicy<V>(String key) => _policyMap[key];

  void setPolicy<V>(String key, V val) => _policyMap[key] = val;
  @override
  dynamic operator [](String key) => _policyMap[key];

  void operator []=(String key, dynamic val) => _policyMap[key] = val;

  PolicyContext copy() {
    PolicyContext policy = PolicyContext(this);
    policy._policyMap.addAll(this._policyMap);
    return policy;
  }

  @override
  Map<String, dynamic> getAll() {
    return Map.of(_policyMap);
  }
}

/// HTTP连接超时时间（毫秒）
const kPcy_http_connTimeoutMs = "http.connTimeout";

/// HTTP读取超时时间（毫秒）
const kPcy_http_readTimeoutMs = "http.readTimeout";

/// HTTP发送超时时间（毫秒）
const kPcy_http_writeTimeoutMs = "http.writeTimeout";

/// 策略配置辅佐类
class PolicyConfigurator {
  final PolicyContext policy;
  PolicyConfigurator(PolicyContext policy)
      : this.policy = policy ?? PolicyContext();
  int get connTimeoutMillis => policy[kPcy_http_connTimeoutMs];
  set connTimeoutMillis(int duration) =>
      policy.setPolicy(kPcy_http_connTimeoutMs, duration);
  int get readTimeoutMillis => policy[kPcy_http_readTimeoutMs];
  set readTimeoutMillis(int duration) =>
      policy.setPolicy(kPcy_http_readTimeoutMs, duration);
  int get writeTimeoutMillis => policy[kPcy_http_writeTimeoutMs];
  set writeTimeoutMillis(int duration) =>
      policy.setPolicy(kPcy_http_writeTimeoutMs, duration);
}
