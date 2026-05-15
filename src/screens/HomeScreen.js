import { View, Text, Button, StyleSheet } from 'react-native';
import { useAuthStore } from '../store/useAuthStore';
import { theme } from '../theme/theme';

export default function HomeScreen() {
    const logout = useAuthStore((state) => state.logout);
    const user = useAuthStore((state) => state.user);

    return (
        <View style={styles.container}>
            <Text style={styles.title}>Benvenuto, {user?.nome || 'Utente'}</Text>
            <Text style={styles.subtitle}>I tuoi Task di oggi</Text>
            <Button title="Logout" color={theme.colors.danger} onPress={logout} />
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: theme.colors.background },
    title: { fontSize: 24, fontWeight: 'bold', color: theme.colors.text, marginBottom: 10 },
    subtitle: { fontSize: 16, color: theme.colors.textSecondary, marginBottom: 20 }
});