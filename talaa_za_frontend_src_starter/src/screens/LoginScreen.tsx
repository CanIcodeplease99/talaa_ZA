import React, { useState } from 'react';
import { View, Text, TextInput, Button, Alert } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '../../App';
import { login, register, setToken } from '../api';

type Props = NativeStackScreenProps<RootStackParamList, 'Login'>;

export default function LoginScreen({ navigation }: Props) {
  const [email, setEmail] = useState('demo@talaa.za');
  const [password, setPassword] = useState('password');

  async function onLogin() {
    try {
      const { token } = await login(email, password);
      setToken(token);
      navigation.replace('Home');
    } catch (e: any) {
      Alert.alert('Login failed', e?.response?.data?.error ?? 'Unknown error');
    }
  }

  async function onRegister() {
    try {
      const { token } = await register(email, password, 'Demo User');
      setToken(token);
      navigation.replace('Home');
    } catch (e: any) {
      Alert.alert('Register failed', e?.response?.data?.error ?? 'Unknown error');
    }
  }

  return (
    <View style={{ padding: 24, gap: 12 }}>
      <Text style={{ fontSize: 22, fontWeight: '600' }}>Talaa ZA</Text>
      <TextInput placeholder="Email" value={email} onChangeText={setEmail}
        autoCapitalize="none" keyboardType="email-address"
        style={{ borderWidth: 1, padding: 12, borderRadius: 8 }} />
      <TextInput placeholder="Password" value={password} onChangeText={setPassword}
        secureTextEntry style={{ borderWidth: 1, padding: 12, borderRadius: 8 }} />
      <Button title="Login" onPress={onLogin} />
      <Button title="Register" onPress={onRegister} />
    </View>
  );
}