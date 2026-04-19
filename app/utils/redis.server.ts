import { createClient } from 'redis'

const redisHost = process.env.REDIS_HOST
const redisPort = process.env.REDIS_PORT || '6380'
const redisPassword = process.env.REDIS_PASSWORD

if (!redisHost) {
  throw new Error('REDIS_HOST is not set')
}

export const redisClient = createClient({
  socket: {
    host: redisHost,
    port: Number(redisPort),
    tls: true,
  },
  password: redisPassword,
})

redisClient.on('error', (err) => {
  console.error('Redis error:', err)
})

let connected = false

export async function getRedisClient() {
  if (!connected) {
    await redisClient.connect()
    connected = true
  }
  return redisClient
}