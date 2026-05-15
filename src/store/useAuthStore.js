import { create } from 'zustand';
import * as SecureStore from 'expo-secure-store';

export const useAuthStore = create((set) => ({
    token: null,
    user: null,
    isLoading: true, // Serve per la schermata di caricamento iniziale

    // Controlla se c'è un token salvato all'avvio dell'app
    initAuth: async () => {
        try {
            const token = await SecureStore.getItemAsync('userToken');
            set({ token, isLoading: false });
        } catch (e) {
            set({ isLoading: false });
        }
    },

    // Esegue il login e salva il token
    login: async (token, user) => {
        await SecureStore.setItemAsync('userToken', token);
        set({ token, user });
    },

    // Esegue il logout e cancella il token
    logout: async () => {
        await SecureStore.deleteItemAsync('userToken');
        set({ token: null, user: null });
    },
}));