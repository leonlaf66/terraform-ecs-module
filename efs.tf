resource "aws_efs_file_system" "main" {
  count            = var.efs_enabled ? 1 : 0
  creation_token   = "${var.app_name}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  tags = merge(var.common_tags, {
    Name = "${var.app_name}-efs"
  })
}

resource "aws_efs_mount_target" "main" {
  count            = var.efs_enabled ? length(var.subnet_ids) : 0
  file_system_id   = aws_efs_file_system.main[0].id
  subnet_id        = var.subnet_ids[count.index]
  security_groups  = [aws_security_group.service_sg.id]
}

resource "aws_efs_access_point" "this" {
  for_each = {
    for key, service in var.services : key => service if var.efs_enabled && service.efs_config != null
  }

  file_system_id = aws_efs_file_system.main[0].id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = each.value.efs_config.path
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }
  tags = merge(var.common_tags, {
    Name = "${var.app_name}-${each.key}-ap"
  })
}