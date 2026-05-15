import { View, Text, Button, StyleSheet } from 'react-native';
import { useAuthStore } from '../store/useAuthStore';
import { theme } from '../theme/theme';

export default function LoginScreen() {
    const login = useAuthStore((state) => state.login);

    return (
        <View style={styles.container}>
            <Text style={styles.title}>AgendaSync</Text>
            <Text style={styles.subtitle}>Schermata di Login (Placeholder)</Text>
            <Button
                title="Simula Login"
                onPress={() => login('token_finto_per_test', { nome: 'Lorenzo' })}
            />
        </View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: theme.colors.background },
    title: { fontSize: 32, fontWeight: 'bold', color: theme.colors.primary, marginBottom: 10 },
    subtitle: { fontSize: 16, color: theme.colors.textSecondary, marginBottom: 20 }
});