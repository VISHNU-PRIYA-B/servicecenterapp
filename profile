import React, { useEffect, useState, useLayoutEffect } from "react";
import {
  View,
  Text,
  Image,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  ScrollView,
  Alert,
} from "react-native";
import * as ImagePicker from "expo-image-picker";
import { graphqlRequest } from "../services/api";
import { useLogout } from "../hooks/Logout";
import { useNavigation } from "@react-navigation/native";

const QUERY = `
  query {
    currentUser {
      id
      name
      profilePic
      admin
      customer
    }
    companyProfile {
      name
      phone
      address
      profilePic
    }
  }
`;

export default function Profile() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [profilePic, setProfilePic] = useState("");
  const [menuVisible, setMenuVisible] = useState(false);

  const navigation = useNavigation();
  const logout = useLogout();

  // header menu icon
  useLayoutEffect(() => {
    navigation.setOptions({
      title: "Profile",
      headerRight: () => (
        <TouchableOpacity onPress={() => setMenuVisible(!menuVisible)}>
          <Image
            source={require("../assets/images/menu-icon.png")}
            style={{ width: 26, height: 26, marginRight: 15 }}
          />
        </TouchableOpacity>
      ),
    });
  }, [menuVisible]);

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const res = await graphqlRequest(QUERY);
      setData(res);

      setProfilePic(
        res.currentUser.profilePic || "https://via.placeholder.com/150"
      );
    } catch (err) {
      console.log("Profile Error:", err);
    } finally {
      setLoading(false);
    }
  };

  const pickImage = async () => {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("Permission Required", "Please allow gallery access.");
      return;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });

    if (!result.canceled) {
      setProfilePic(result.assets[0].uri);
      Alert.alert("Success", "Profile picture updated (Preview Only)");
    }
  };

  if (loading)
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" />
      </View>
    );

  const { currentUser, companyProfile } = data;

  const isAdmin = currentUser.admin;
  const isCustomer = currentUser.customer;

  return (
    <View style={{ flex: 1 }}>
      {/* DROPDOWN MENU */}
      {menuVisible && (
        <View style={styles.menuBox}>

          {/* CUSTOMER MENU */}
          {isCustomer && (
            <>
              <TouchableOpacity
                style={styles.menuItem}
                onPress={() => {
                  setMenuVisible(false);
                  navigation.navigate("ApproveEstimation");
                }}
              >
                <Text style={styles.menuText}>View Submitted Requests</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.menuItem}
                onPress={() => {
                  setMenuVisible(false);
                  navigation.navigate("CreateRepairRequest");
                }}
              >
                <Text style={styles.menuText}>Submit New Request</Text>
              </TouchableOpacity>
            </>
          )}

          {/* ADMIN MENU */}
          {isAdmin && (
            <>
              <TouchableOpacity
                style={styles.menuItem}
                onPress={() => {
                  setMenuVisible(false);
                  navigation.navigate("ViewRequest");
                }}
              >
                <Text style={styles.menuText}>View Requests</Text>
              </TouchableOpacity>
            </>
          )}

          {/* LOGOUT */}
          <TouchableOpacity
            style={[styles.menuItem, { borderTopWidth: 1, borderColor: "#eee" }]}
            onPress={logout}
          >
            <Text style={[styles.menuText, { color: "red" }]}>Logout</Text>
          </TouchableOpacity>
        </View>
      )}

      <ScrollView showsVerticalScrollIndicator={false}>
        <View style={styles.headerBackground} />

        <View style={styles.card}>
          <TouchableOpacity onPress={pickImage}>
            <Image source={{ uri: profilePic }} style={styles.avatar} />
          </TouchableOpacity>

          <Text style={styles.tapText}>Tap to change profile picture</Text>

          {isCustomer && (
            <Text style={styles.nameText}>{currentUser.name}</Text>
          )}

          {/* Admin info */}
          {isAdmin && (
            <View style={{ marginTop: 15 }}>
              <Text style={styles.companyName}>{companyProfile.name}</Text>
              <Text style={styles.companyLabel}>📞 {companyProfile.phone}</Text>
              <Text style={styles.companyLabel}>📍 {companyProfile.address}</Text>
            </View>
          )}

          {/* Customer Company */}
          {isCustomer && (
            <View style={{ marginTop: 10 }}>
              <Text style={styles.companyLabel}>Company</Text>
              <Text style={styles.companyName}>{companyProfile.name}</Text>
            </View>
          )}

        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  headerBackground: {
    height: 140,
    backgroundColor: "#007bff",
    borderBottomLeftRadius: 30,
    borderBottomRightRadius: 30,
  },

  card: {
    backgroundColor: "#fff",
    marginHorizontal: 20,
    marginTop: -70,
    borderRadius: 20,
    paddingVertical: 30,
    paddingHorizontal: 20,
    alignItems: "center",
    elevation: 5,
  },

  avatar: {
    width: 140,
    height: 140,
    borderRadius: 70,
    borderWidth: 3,
    borderColor: "#007bff",
  },

  tapText: { color: "#007bff", marginTop: 10, fontSize: 14 },

  nameText: { fontSize: 26, fontWeight: "bold", marginTop: 18 },

  companyLabel: { fontSize: 14, color: "#777", textAlign: "center" },

  companyName: {
    fontSize: 20,
    fontWeight: "700",
    textAlign: "center",
    marginTop: 5,
  },

  menuBox: {
    position: "absolute",
    top: 55,
    right: 15,
    backgroundColor: "#fff",
    borderRadius: 10,
    elevation: 8,
    width: 220,
    zIndex: 100,
  },

  menuItem: { padding: 14 },

  menuText: { fontSize: 16 },

  center: { flex: 1, justifyContent: "center", alignItems: "center" },
});
