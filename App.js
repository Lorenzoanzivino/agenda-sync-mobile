import { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import AppNavigator from './src/navigation/AppNavigator';
import { useAuthStore } from './src/store/useAuthStore';

export default function App() {
  const initAuth = useAuthStore((state) => state.initAuth);

  // All'avvio dell'app, controlla se l'utente aveva già fatto l'accesso in passato
  useEffect(() => {
    initAuth();
  }, []);

  return (
      <NavigationContainer>
        <AppNavigator />
      </NavigationContainer>
  );
}