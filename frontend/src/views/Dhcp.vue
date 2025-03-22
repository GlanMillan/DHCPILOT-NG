<template>
  <div class="dhcp-container">
    <el-row :gutter="20">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>DHCP服务配置</span>
              <el-button type="primary" @click="handleSave">保存配置</el-button>
            </div>
          </template>
          <el-form
            ref="configFormRef"
            :model="configForm"
            :rules="configRules"
            label-width="120px"
          >
            <el-form-item label="服务状态" prop="enabled">
              <el-switch v-model="configForm.enabled" />
            </el-form-item>
            <el-form-item label="默认租约时间" prop="defaultLeaseTime">
              <el-input-number
                v-model="configForm.defaultLeaseTime"
                :min="60"
                :max="86400"
                :step="60"
              />
              <span class="form-text">秒</span>
            </el-form-item>
            <el-form-item label="最大租约时间" prop="maxLeaseTime">
              <el-input-number
                v-model="configForm.maxLeaseTime"
                :min="60"
                :max="604800"
                :step="60"
              />
              <span class="form-text">秒</span>
            </el-form-item>
            <el-form-item label="DNS服务器" prop="dnsServers">
              <el-select
                v-model="configForm.dnsServers"
                multiple
                filterable
                allow-create
                default-first-option
                placeholder="请输入DNS服务器地址"
              >
                <el-option
                  v-for="item in dnsOptions"
                  :key="item"
                  :label="item"
                  :value="item"
                />
              </el-select>
            </el-form-item>
            <el-form-item label="网关地址" prop="gateway">
              <el-input v-model="configForm.gateway" placeholder="请输入网关地址" />
            </el-form-item>
            <el-form-item label="子网掩码" prop="subnetMask">
              <el-input v-model="configForm.subnetMask" placeholder="请输入子网掩码" />
            </el-form-item>
            <el-form-item label="IP地址池">
              <el-row :gutter="10">
                <el-col :span="11">
                  <el-form-item prop="ipRange.start">
                    <el-input v-model="configForm.ipRange.start" placeholder="起始IP" />
                  </el-form-item>
                </el-col>
                <el-col :span="2" class="text-center">
                  <span class="form-text">至</span>
                </el-col>
                <el-col :span="11">
                  <el-form-item prop="ipRange.end">
                    <el-input v-model="configForm.ipRange.end" placeholder="结束IP" />
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form-item>
            <el-form-item label="保留地址">
              <el-table :data="configForm.reservedIps" style="width: 100%">
                <el-table-column prop="mac" label="MAC地址" />
                <el-table-column prop="ip" label="IP地址" />
                <el-table-column prop="hostname" label="主机名" />
                <el-table-column label="操作" width="120">
                  <template #default="{ $index }">
                    <el-button
                      type="danger"
                      link
                      @click="handleRemoveReservedIp($index)"
                    >
                      删除
                    </el-button>
                  </template>
                </el-table-column>
              </el-table>
              <el-button
                type="primary"
                link
                class="add-button"
                @click="handleAddReservedIp"
              >
                添加保留地址
              </el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog
      v-model="reservedIpDialog.visible"
      title="添加保留地址"
      width="500px"
    >
      <el-form
        ref="reservedIpFormRef"
        :model="reservedIpDialog.form"
        :rules="reservedIpDialog.rules"
        label-width="100px"
      >
        <el-form-item label="MAC地址" prop="mac">
          <el-input v-model="reservedIpDialog.form.mac" placeholder="请输入MAC地址" />
        </el-form-item>
        <el-form-item label="IP地址" prop="ip">
          <el-input v-model="reservedIpDialog.form.ip" placeholder="请输入IP地址" />
        </el-form-item>
        <el-form-item label="主机名" prop="hostname">
          <el-input v-model="reservedIpDialog.form.hostname" placeholder="请输入主机名" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="reservedIpDialog.visible = false">取消</el-button>
          <el-button type="primary" @click="handleConfirmReservedIp">
            确认
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>
<script setup lang="ts">
import { ref, reactive } from 'vue'
import type { FormInstance } from 'element-plus'
import { ElMessage } from 'element-plus'

const configFormRef = ref<FormInstance>()
const reservedIpFormRef = ref<FormInstance>()

const configForm = reactive({
  enabled: true,
  defaultLeaseTime: 86400,
  maxLeaseTime: 604800,
  dnsServers: ['8.8.8.8', '8.8.4.4'],
  gateway: '192.168.1.1',
  subnetMask: '255.255.255.0',
  ipRange: {
    start: '192.168.1.100',
    end: '192.168.1.200'
  },
  reservedIps: [
    {
      mac: '00:11:22:33:44:55',
      ip: '192.168.1.50',
      hostname: 'server-1'
    }
  ]
})

const configRules = {
  gateway: [
    { required: true, message: '请输入网关地址', trigger: 'blur' },
    { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: '请输入正确的IP地址格式', trigger: 'blur' }
  ],
  subnetMask: [
    { required: true, message: '请输入子网掩码', trigger: 'blur' },
    { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: '请输入正确的子网掩码格式', trigger: 'blur' }
  ],
  'ipRange.start': [
    { required: true, message: '请输入起始IP地址', trigger: 'blur' },
    { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: '请输入正确的IP地址格式', trigger: 'blur' }
  ],
  'ipRange.end': [
    { required: true, message: '请输入结束IP地址', trigger: 'blur' },
    { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: '请输入正确的IP地址格式', trigger: 'blur' }
  ]
}

const dnsOptions = [
  '8.8.8.8',
  '8.8.4.4',
  '114.114.114.114',
  '223.5.5.5'
]

const reservedIpDialog = reactive({
  visible: false,
  form: {
    mac: '',
    ip: '',
    hostname: ''
  },
  rules: {
    mac: [
      { required: true, message: '请输入MAC地址', trigger: 'blur' },
      { pattern: /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/, message: '请输入正确的MAC地址格式', trigger: 'blur' }
    ],
    ip: [
      { required: true, message: '请输入IP地址', trigger: 'blur' },
      { pattern: /^(\d{1,3}\.){3}\d{1,3}$/, message: '请输入正确的IP地址格式', trigger: 'blur' }
    ],
    hostname: [
      { required: true, message: '请输入主机名', trigger: 'blur' }
    ]
  }
})

const handleSave = async () => {
  if (!configFormRef.value) return
  
  await configFormRef.value.validate((valid) => {
    if (valid) {
      // TODO: 实现保存配置逻辑
      ElMessage.success('配置保存成功')
    }
  })
}

const handleAddReservedIp = () => {
  reservedIpDialog.form = {
    mac: '',
    ip: '',
    hostname: ''
  }
  reservedIpDialog.visible = true
}

const handleConfirmReservedIp = async () => {
  if (!reservedIpFormRef.value) return
  
  await reservedIpFormRef.value.validate((valid) => {
    if (valid) {
      configForm.reservedIps.push({ ...reservedIpDialog.form })
      reservedIpDialog.visible = false
      ElMessage.success('添加成功')
    }
  })
}

const handleRemoveReservedIp = (index: number) => {
  configForm.reservedIps.splice(index, 1)
  ElMessage.success('删除成功')
}
</script>

<style scoped>
.dhcp-container {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.form-text {
  margin-left: 10px;
  color: #909399;
}

.text-center {
  text-align: center;
  line-height: 32px;
}

.add-button {
  margin-top: 10px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style> 