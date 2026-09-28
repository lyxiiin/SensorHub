class DeviceGroup {
  final int? groupId;
  final String groupName;
  final int sortOrder;
  final int createdAt;
  DeviceGroup({
   this.groupId,
    required this.groupName,
    required this.sortOrder,
    required this.createdAt
  });

  factory DeviceGroup.fromMap(Map<String, dynamic> map) {
    return DeviceGroup(
        groupId: map['groupId'],
        groupName: map['groupName'],
        sortOrder: map['sortOrder'],
        createdAt: map['createdAt']
    );
  }
  Map<String, dynamic> toMap() => {
    'groupId': groupId,
    'groupName': groupName,
    'sortOrder': sortOrder,
    'createdAt': createdAt,
  };

  /// 分组是不可变对象：重命名 / 重排时用 copyWith 生成新实例
  DeviceGroup copyWith({
    int? groupId,
    String? groupName,
    int? sortOrder,
    int? createdAt,
  }) {
    return DeviceGroup(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}