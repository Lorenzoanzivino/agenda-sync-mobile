import axios from 'axios';
import * as SecureStore from 'expo-secure-store';

// SOSTITUISCI QUESTO IP CON QUELLO DELLA TUA RETE WI-FI
// Puoi trovarlo scrivendo 'ip a' o 'ifconfig' nel terminale linux
const LOCAL_IP = '172.22.76.101'; // <-- MODIFICA QUI
const BASE_URL = `http://${LOCAL_IP}:8080/api/v1`;

export const apiClient = axios.create({
    baseURL: BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Interceptor: inietta automaticamente il Token in ogni richiesta
apiClient.interceptors.request.use(
    async (config) => {
        const token = await SecureStore.getItemAsync('userToken');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);