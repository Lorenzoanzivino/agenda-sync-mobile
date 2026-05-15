import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ActivityIndicator, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAuthStore } from '../store/useAuthStore';
import { theme } from '../theme/theme';

import LoginScreen from '../screens/LoginScreen';
import HomeScreen from '../screens/HomeScreen';

const Tab = createBottomTabNavigator();
const Stack = createNativeStackNavigator();

// 1. Navigatore per utenti NON loggati
function AuthStack() {
    return (
        <Stack.Navigator screenOptions={{ headerShown: false }}>
            <Stack.Screen name="Login" component={LoginScreen} />
        </Stack.Navigator>
    );
}

// 2. Navigatore per utenti LOGGATI (Bottom Tabs)
function MainTabs() {
    return (
        <Tab.Navigator
            screenOptions={({ route }) => ({
                headerStyle: { backgroundColor: theme.colors.surface },
                headerTintColor: theme.colors.primary,
                tabBarActiveTintColor: theme.colors.primary,
                tabBarInactiveTintColor: theme.colors.textSecondary,
                tabBarStyle: { borderTopWidth: 0, elevation: 10 },
                tabBarIcon: ({ focused, color, size }) => {
                    let iconName;
                    if (route.name === 'Home') iconName = focused ? 'calendar' : 'calendar-outline';
                    return <Ionicons name={iconName} size={size} color={color} />;
                },
            })}
        >
            <Tab.Screen name="Home" component={HomeScreen} options={{ title: 'I Miei Task' }} />
            {/* Qui aggiungeremo in futuro le tab Calendars e Profile */}
        </Tab.Navigator>
    );
}

// 3. Navigatore Radice che gestisce lo Switch
export default function AppNavigator() {
    const { token, isLoading } = useAuthStore();

    // Mostra un loader mentre controlla il SecureStore all'avvio
    if (isLoading) {
        return (
            <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: theme.colors.background }}>
                <ActivityIndicator size="large" color={theme.colors.primary} />
            </View>
        );
    }

    // Se c't un token, vai all'app, altrimenti vai al Login
    return token ? <MainTabs /> : <AuthStack />;
}