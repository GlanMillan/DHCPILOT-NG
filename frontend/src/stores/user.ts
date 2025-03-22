import { defineStore } from 'pinia'
import { ref } from 'vue'
import { login } from '@/api'

interface UserInfo {
  id: string
  username: string
  role: string
  token: string
}

export const useUserStore = defineStore('user', () => {
  const userInfo = ref<UserInfo | null>(null)
  const isLoggedIn = ref(false)

  const setUserInfo = (info: UserInfo | null) => {
    userInfo.value = info
    isLoggedIn.value = !!info
    if (info?.token) {
      localStorage.setItem('token', info.token)
    } else {
      localStorage.removeItem('token')
    }
  }

  const loginUser = async (username: string, password: string) => {
    try {
      const data = await login({ username, password })
      setUserInfo(data)
      return true
    } catch (error) {
      return false
    }
  }

  const logout = () => {
    setUserInfo(null)
  }

  return {
    userInfo,
    isLoggedIn,
    loginUser,
    logout
  }
}) 