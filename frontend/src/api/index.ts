import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import { ElMessage } from 'element-plus'

const api: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_APP_API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
api.interceptors.response.use(
  (response: AxiosResponse) => {
    const { data } = response
    if (data.code === 0) {
      return data.data
    }
    ElMessage.error(data.message || '请求失败')
    return Promise.reject(new Error(data.message || '请求失败'))
  },
  (error) => {
    if (error.response) {
      switch (error.response.status) {
        case 401:
          // 未授权，清除token并跳转到登录页
          localStorage.removeItem('token')
          window.location.href = '/login'
          break
        case 403:
          ElMessage.error('没有权限访问')
          break
        case 404:
          ElMessage.error('请求的资源不存在')
          break
        case 500:
          ElMessage.error('服务器错误')
          break
        default:
          ElMessage.error('网络错误')
      }
    } else {
      ElMessage.error('网络错误')
    }
    return Promise.reject(error)
  }
)

// 登录
export const login = (data: { username: string; password: string }) => {
  return api.post('/auth/login', data)
}

// 获取系统信息
export const getSystemInfo = () => {
  return api.get('/system/info')
}

// 获取DHCP配置
export const getDhcpConfig = () => {
  return api.get('/dhcp/config')
}

// 更新DHCP配置
export const updateDhcpConfig = (data: any) => {
  return api.put('/dhcp/config', data)
}

// 获取DHCP状态
export const getDhcpStatus = () => {
  return api.get('/dhcp/status')
}

// 获取DHCP日志
export const getDhcpLogs = (params: { page: number; pageSize: number }) => {
  return api.get('/dhcp/logs', { params })
}

// 获取系统设置
export const getSettings = () => {
  return api.get('/settings')
}

// 更新系统设置
export const updateSettings = (data: any) => {
  return api.put('/settings', data)
}

// 获取备份列表
export const getBackups = () => {
  return api.get('/backups')
}

// 创建备份
export const createBackup = () => {
  return api.post('/backups')
}

// 恢复备份
export const restoreBackup = (id: string) => {
  return api.post(`/backups/${id}/restore`)
}

// 删除备份
export const deleteBackup = (id: string) => {
  return api.delete(`/backups/${id}`)
}

export default api 