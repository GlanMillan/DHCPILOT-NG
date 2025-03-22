<template>
  <div class="settings-container">
    <el-row :gutter="20">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>系统设置</span>
              <el-button type="primary" @click="handleSave">保存设置</el-button>
            </div>
          </template>
          <el-form
            ref="settingsFormRef"
            :model="settingsForm"
            :rules="settingsRules"
            label-width="120px"
          >
            <el-form-item label="系统名称" prop="systemName">
              <el-input v-model="settingsForm.systemName" placeholder="请输入系统名称" />
            </el-form-item>
            <el-form-item label="管理员账号" prop="adminUsername">
              <el-input v-model="settingsForm.adminUsername" placeholder="请输入管理员账号" />
            </el-form-item>
            <el-form-item label="管理员密码" prop="adminPassword">
              <el-input
                v-model="settingsForm.adminPassword"
                type="password"
                placeholder="请输入管理员密码"
                show-password
              />
            </el-form-item>
            <el-form-item label="确认密码" prop="confirmPassword">
              <el-input
                v-model="settingsForm.confirmPassword"
                type="password"
                placeholder="请再次输入密码"
                show-password
              />
            </el-form-item>
            <el-form-item label="系统日志">
              <el-switch v-model="settingsForm.enableLogging" />
            </el-form-item>
            <el-form-item label="日志级别" prop="logLevel">
              <el-select v-model="settingsForm.logLevel" placeholder="请选择日志级别">
                <el-option label="DEBUG" value="debug" />
                <el-option label="INFO" value="info" />
                <el-option label="WARNING" value="warning" />
                <el-option label="ERROR" value="error" />
              </el-select>
            </el-form-item>
            <el-form-item label="日志保留天数" prop="logRetentionDays">
              <el-input-number
                v-model="settingsForm.logRetentionDays"
                :min="1"
                :max="90"
                :step="1"
              />
            </el-form-item>
            <el-form-item label="自动备份">
              <el-switch v-model="settingsForm.enableAutoBackup" />
            </el-form-item>
            <el-form-item label="备份周期" prop="backupInterval">
              <el-select v-model="settingsForm.backupInterval" placeholder="请选择备份周期">
                <el-option label="每天" value="daily" />
                <el-option label="每周" value="weekly" />
                <el-option label="每月" value="monthly" />
              </el-select>
            </el-form-item>
            <el-form-item label="备份时间" prop="backupTime">
              <el-time-picker
                v-model="settingsForm.backupTime"
                format="HH:mm"
                placeholder="请选择备份时间"
              />
            </el-form-item>
            <el-form-item label="备份保留数量" prop="backupRetentionCount">
              <el-input-number
                v-model="settingsForm.backupRetentionCount"
                :min="1"
                :max="30"
                :step="1"
              />
            </el-form-item>
            <el-form-item label="系统通知">
              <el-switch v-model="settingsForm.enableNotification" />
            </el-form-item>
            <el-form-item label="通知方式" prop="notificationMethods">
              <el-checkbox-group v-model="settingsForm.notificationMethods">
                <el-checkbox label="email">邮件</el-checkbox>
                <el-checkbox label="sms">短信</el-checkbox>
                <el-checkbox label="webhook">Webhook</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="通知邮箱" prop="notificationEmail">
              <el-input
                v-model="settingsForm.notificationEmail"
                placeholder="请输入通知邮箱"
                :disabled="!settingsForm.notificationMethods.includes('email')"
              />
            </el-form-item>
            <el-form-item label="通知手机" prop="notificationPhone">
              <el-input
                v-model="settingsForm.notificationPhone"
                placeholder="请输入通知手机"
                :disabled="!settingsForm.notificationMethods.includes('sms')"
              />
            </el-form-item>
            <el-form-item label="Webhook地址" prop="webhookUrl">
              <el-input
                v-model="settingsForm.webhookUrl"
                placeholder="请输入Webhook地址"
                :disabled="!settingsForm.notificationMethods.includes('webhook')"
              />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>
<script setup lang="ts">
import { ref, reactive } from 'vue'
import type { FormInstance } from 'element-plus'
import { ElMessage } from 'element-plus'

const settingsFormRef = ref<FormInstance>()

const settingsForm = reactive({
  systemName: 'DHCPLIOT-NG',
  adminUsername: 'admin',
  adminPassword: '',
  confirmPassword: '',
  enableLogging: true,
  logLevel: 'info',
  logRetentionDays: 30,
  enableAutoBackup: true,
  backupInterval: 'daily',
  backupTime: new Date(2000, 0, 1, 2, 0),
  backupRetentionCount: 7,
  enableNotification: true,
  notificationMethods: ['email'],
  notificationEmail: '',
  notificationPhone: '',
  webhookUrl: ''
})

const validatePass = (rule: any, value: string, callback: any) => {
  if (value === '') {
    callback(new Error('请输入密码'))
  } else {
    if (settingsForm.confirmPassword !== '') {
      if (settingsFormRef.value) {
        settingsFormRef.value.validateField('confirmPassword')
      }
    }
    callback()
  }
}

const validatePass2 = (rule: any, value: string, callback: any) => {
  if (value === '') {
    callback(new Error('请再次输入密码'))
  } else if (value !== settingsForm.adminPassword) {
    callback(new Error('两次输入密码不一致!'))
  } else {
    callback()
  }
}

const settingsRules = {
  systemName: [
    { required: true, message: '请输入系统名称', trigger: 'blur' }
  ],
  adminUsername: [
    { required: true, message: '请输入管理员账号', trigger: 'blur' },
    { min: 3, max: 20, message: '长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  adminPassword: [
    { validator: validatePass, trigger: 'blur' },
    { min: 6, max: 20, message: '长度在 6 到 20 个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { validator: validatePass2, trigger: 'blur' }
  ],
  logLevel: [
    { required: true, message: '请选择日志级别', trigger: 'change' }
  ],
  backupInterval: [
    { required: true, message: '请选择备份周期', trigger: 'change' }
  ],
  backupTime: [
    { required: true, message: '请选择备份时间', trigger: 'change' }
  ],
  notificationEmail: [
    { type: 'email', message: '请输入正确的邮箱地址', trigger: 'blur' }
  ],
  notificationPhone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ],
  webhookUrl: [
    { type: 'url', message: '请输入正确的URL地址', trigger: 'blur' }
  ]
}

const handleSave = async () => {
  if (!settingsFormRef.value) return
  
  await settingsFormRef.value.validate((valid) => {
    if (valid) {
      // TODO: 实现保存设置逻辑
      ElMessage.success('设置保存成功')
    }
  })
}
</script>

<style scoped>
.settings-container {
  padding: 20px;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style> 