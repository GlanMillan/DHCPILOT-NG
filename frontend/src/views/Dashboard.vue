<template>
  <div class="dashboard-container">
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>总客户端数</span>
              <el-icon><User /></el-icon>
            </div>
          </template>
          <div class="card-content">
            <div class="number">{{ stats.totalClients }}</div>
            <div class="trend">
              <span :class="{ 'up': stats.clientGrowth > 0, 'down': stats.clientGrowth < 0 }">
                {{ stats.clientGrowth > 0 ? '+' : '' }}{{ stats.clientGrowth }}%
              </span>
              较上月
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>活跃客户端</span>
              <el-icon><Connection /></el-icon>
            </div>
          </template>
          <div class="card-content">
            <div class="number">{{ stats.activeClients }}</div>
            <div class="trend">
              <span :class="{ 'up': stats.activeGrowth > 0, 'down': stats.activeGrowth < 0 }">
                {{ stats.activeGrowth > 0 ? '+' : '' }}{{ stats.activeGrowth }}%
              </span>
              较上月
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>IP使用率</span>
              <el-icon><DataLine /></el-icon>
            </div>
          </template>
          <div class="card-content">
            <div class="number">{{ stats.ipUsage }}%</div>
            <div class="trend">
              <span :class="{ 'up': stats.ipGrowth > 0, 'down': stats.ipGrowth < 0 }">
                {{ stats.ipGrowth > 0 ? '+' : '' }}{{ stats.ipGrowth }}%
              </span>
              较上月
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>服务状态</span>
              <el-icon><Monitor /></el-icon>
            </div>
          </template>
          <div class="card-content">
            <div class="number">
              <el-tag :type="stats.serviceStatus === 'running' ? 'success' : 'danger'">
                {{ stats.serviceStatus === 'running' ? '运行中' : '已停止' }}
              </el-tag>
            </div>
            <div class="trend">
              运行时间：{{ stats.uptime }}
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="chart-row">
      <el-col :span="16">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>客户端趋势</span>
              <el-radio-group v-model="clientChartType" size="small">
                <el-radio-button label="day">日</el-radio-button>
                <el-radio-button label="week">周</el-radio-button>
                <el-radio-button label="month">月</el-radio-button>
              </el-radio-group>
            </div>
          </template>
          <div class="chart-container">
            <!-- TODO: 添加图表组件 -->
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>IP分配情况</span>
            </div>
          </template>
          <div class="chart-container">
            <!-- TODO: 添加饼图组件 -->
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="table-row">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>最近活动</span>
              <el-button type="primary" link>查看全部</el-button>
            </div>
          </template>
          <el-table :data="recentActivities" style="width: 100%">
            <el-table-column prop="time" label="时间" width="180" />
            <el-table-column prop="type" label="类型" width="120">
              <template #default="{ row }">
                <el-tag :type="getActivityTypeTag(row.type)">
                  {{ getActivityTypeText(row.type) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="client" label="客户端" />
            <el-table-column prop="ip" label="IP地址" width="140" />
            <el-table-column prop="details" label="详情" />
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import {
  User,
  Connection,
  DataLine,
  Monitor
} from '@element-plus/icons-vue'

const clientChartType = ref('day')

const stats = reactive({
  totalClients: 256,
  clientGrowth: 12.5,
  activeClients: 180,
  activeGrowth: 8.3,
  ipUsage: 75,
  ipGrowth: -2.1,
  serviceStatus: 'running',
  uptime: '7天12小时'
})

const recentActivities = [
  {
    time: '2024-03-20 14:30:00',
    type: 'lease',
    client: 'DESKTOP-ABC123',
    ip: '192.168.1.100',
    details: '获取IP地址租约'
  },
  {
    time: '2024-03-20 14:25:00',
    type: 'release',
    client: 'LAPTOP-XYZ789',
    ip: '192.168.1.101',
    details: '释放IP地址租约'
  },
  {
    time: '2024-03-20 14:20:00',
    type: 'renew',
    client: 'MOBILE-123456',
    ip: '192.168.1.102',
    details: '续约IP地址租约'
  }
]

const getActivityTypeTag = (type: string) => {
  const types: Record<string, string> = {
    lease: 'success',
    release: 'info',
    renew: 'warning'
  }
  return types[type] || 'info'
}

const getActivityTypeText = (type: string) => {
  const types: Record<string, string> = {
    lease: '获取租约',
    release: '释放租约',
    renew: '续约'
  }
  return types[type] || type
}
</script>

<style scoped>
.dashboard-container {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-content {
  text-align: center;
}

.number {
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 8px;
}

.trend {
  font-size: 14px;
  color: #909399;
}

.trend .up {
  color: #67c23a;
}

.trend .down {
  color: #f56c6c;
}

.chart-row {
  margin-top: 20px;
}

.table-row {
  margin-top: 20px;
}

.chart-container {
  height: 300px;
}
</style> 