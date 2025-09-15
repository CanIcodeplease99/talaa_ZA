import React, { useEffect, useState } from 'react';
import { View, Text, TextInput, Button, Alert } from 'react-native';
import { getMe, updateMe } from '../api';

export default function ProfileScreen() {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const { user } = await getMe();
        setEmail(user?.email ?? '');
        setName(user?.name ?? '');
      } catch (e: any) {
        Alert.alert('Error', e?.response?.data?.error ?? 'Failed to load profile');
      }
    })();
  }, []);

  async function save() {
    try {
      const { user } = await updateMe(name);
      setName(user?.name ?? '');
      Alert.alert('Saved', 'Profile updated');
    } catch (e: any) {
      Alert.alert('Error', e?.response?.data?.error ?? 'Failed to save');
    }
  }

  return (
    <View style={{ padding: 24, gap: 12 }}>
      <Text style={{ fontSize: 18 }}>Email</Text>
      <Text style={{ paddingVertical: 4 }}>{email}</Text>
      <Text style={{ fontSize: 18, marginTop: 12 }}>Display name</Text>
      <TextInput value={name} onChangeText={setName} style={{ borderWidth: 1, padding: 12, borderRadius: 8 }} />
      <Button title="Save" onPress={save} />
    </View>
  );
}