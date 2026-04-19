import { getRedisClient } from '../utils/redis.server'

const API_KEY = process.env.WEATHER_API_KEY
const TEN_MINUTES = 60 * 10

interface FetchWeatherDataParams {
  lat: number
  lon: number
  units: string
}

export async function fetchWeatherData({
  lat,
  lon,
  units,
}: FetchWeatherDataParams) {
  const baseURL = 'https://api.openweathermap.org/data/2.5/weather'
  const queryString = `lat=${lat}&lon=${lon}&units=${units}&appid=${API_KEY}`
  const cacheKey = `weather:${queryString}`

  const redis = await getRedisClient()
  const cached = await redis.get(cacheKey)

  if (cached) {
    return JSON.parse(cached)
  }

  const response = await fetch(`${baseURL}?${queryString}`)
  const data = await response.json()

  await redis.setEx(cacheKey, TEN_MINUTES, JSON.stringify(data))
  return data
}

export async function getGeoCoordsForPostalCode(
  postalCode: string,
  countryCode: string,
) {
  const url = `http://api.openweathermap.org/geo/1.0/zip?zip=${postalCode},${countryCode}&appid=${API_KEY}`
  const response = await fetch(url)
  return response.json()
}