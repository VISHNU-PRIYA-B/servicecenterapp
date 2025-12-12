// @ts-nocheck
import React, { useEffect, useState, useLayoutEffect } from "react";
import {
  View,
  Text,
  Image,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Alert,
} from "react-native";
import * as ImagePicker from "expo-image-picker";
import { graphqlRequest } from "../services/api";
import { useLogout } from "../hooks/Logout";
import { UserContext } from "../components/ui/UserContext";
import { useNavigation } from "@react-navigation/native";

// Query user + company profile
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
      ownerName
      companyName
      phone
      address
    }
  }
`;

// Profile pic update (unchanged)
const UPDATE_PROFILE_PIC = `
  mutation UpdateProfilePic($profilePic: String!) {
    updateProfile(profilePic: $profilePic) {
      success
      message
      user {
        id
        profilePic
      }
    }
  }
`;

// CREATE / UPDATE company profile
const SAVE_COMPANY = `
  mutation SaveCompany(
    $ownerName: String!,
    $companyName: String!,
    $phone: String!,
    $address: String!
  ) {
    createOrUpdateCompanyProfile(
      ownerName: $ownerName,
      companyName: $companyName,
      phone: $phone,
      address: $address
    ) {
      success
      message
      companyProfile {
        ownerName
        companyName
        phone
        address
      }
    }
  }
`;

export default function Profile() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [editMode, setEditMode] = useState(false); // Admin edit/create mode

  const [ownerName, setOwnerName] = useState("");
  const [companyName, setCompanyName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  

  const [profilePic, setProfilePic] = useState("");
  const [menuVisible, setMenuVisible] = useState(false);
  const [uploading, setUploading] = useState(false);

  const navigation = useNavigation();
  const logout = useLogout();

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

  // Load Profile
  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const res = await graphqlRequest(QUERY);
      setData(res);

      setProfilePic(res.currentUser.profilePic);

      if (res.companyProfile) {
        setOwnerName(res.companyProfile.ownerName);
        setCompanyName(res.companyProfile.companyName);
        setPhone(res.companyProfile.phone);
        setAddress(res.companyProfile.address);
      }
    } catch (err) {
      console.log("Profile Error:", err);
    } finally {
      setLoading(false);
    }
  };

  // Convert image to base64
  const convertToBase64 = async (uri: string) => {
    const response = await fetch(uri);
    const blob = await response.blob();
    return new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  };

  // Pick image (unchanged)
  const pickImage = async () => {
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) return;

    const result = await ImagePicker.launchImageLibraryAsync({
      allowsEditing: true,
      quality: 0.8,
    });

    if (!result.canceled) {
      const uri = result.assets[0].uri;
      setProfilePic(uri);

      try {
        setUploading(true);
        const base64 = await convertToBase64(uri);
        await graphqlRequest(UPDATE_PROFILE_PIC, { profilePic: base64 });
        Alert.alert("Success", "Profile picture updated!");
      } catch (e) {
        Alert.alert("Error", "Failed to update picture");
      }
      setUploading(false);
    }
  };

  // Save (Create or Update company profile)
  const saveCompany = async () => {
    if (!ownerName || !companyName || !phone || !address) {
      Alert.alert("Error", "All fields are required");
      return;
    }

    try {
      const res = await graphqlRequest(SAVE_COMPANY, {
        ownerName,
        companyName,
        phone,
        address,
      });

      if (res.createOrUpdateCompanyProfile.success) {
        Alert.alert("Success", "Company details saved!");
        setEditMode(false);
        fetchProfile();
      }
    } catch (e) {
      Alert.alert("Error", "Failed to save company profile");
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
      {/* Dropdown menu */}
      {menuVisible && (
        <View style={styles.menuBox}>
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

          {isAdmin && (
            <>
            <TouchableOpacity
              style={styles.menuItem}
              onPress={() => {
                setMenuVisible(false);
                setEditMode(true); // open create/edit
              }}
            >
              <Text style={styles.menuText}>
                {companyProfile ? "Edit Company Info" : "Create Company Info"}
              </Text>
            </TouchableOpacity>
              <TouchableOpacity
                style={styles.menuItem}
                onPress={() => {
                  setMenuVisible(false);
                  navigation.navigate("ViewRequest");
                }}
              >
                <Text style={styles.menuText}>View Request</Text>
              </TouchableOpacity>
            </>
          )}

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
          {/* Profile Picture */}
          <TouchableOpacity onPress={pickImage}>
            {uploading ? (
              <View style={[styles.avatar, styles.center]}>
                <ActivityIndicator size="small" />
              </View>
            ) : (
              <Image source={{ uri: profilePic }} style={styles.avatar} />
            )}
          </TouchableOpacity>

          <Text style={styles.tapText}>Tap to change profile picture</Text>

          {/* Customer View */}
          {isCustomer && (
            <View style={{ marginTop: 20 }}>
              <Text style={styles.nameLabel}>Name:</Text>
              <Text style={styles.nameText}>{currentUser.name}</Text>

              <Text style={styles.companyLabel}>Company:</Text>
              <Text style={styles.companyName}>{companyProfile?.companyName || "N/A"}</Text>
            </View>
          )}

          {/* Admin Create/Edit Form */}
          {isAdmin && editMode && (
            <View style={{ width: "100%", marginTop: 20 }}>
              <TextInput
                placeholder="Owner Name"
                value={ownerName}
                onChangeText={setOwnerName}
                style={styles.input}
              />
              <TextInput
                placeholder="Company Name"
                value={companyName}
                onChangeText={setCompanyName}
                style={styles.input}
              />
              <TextInput
                placeholder="Phone Number"
                value={phone}
                onChangeText={setPhone}
                style={styles.input}
              />
              <TextInput
                placeholder="Address"
                value={address}
                onChangeText={setAddress}
                style={styles.input}
              />

              <TouchableOpacity style={styles.saveBtn} onPress={saveCompany}>
                <Text style={styles.saveText}>Save</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => setEditMode(false)}
              >
                <Text style={{ color: "#444" }}>Cancel</Text>
              </TouchableOpacity>
            </View>
          )}

          {/* Admin View Mode */}
          {isAdmin && !editMode && companyProfile && (
            <View style={{ marginTop: 20 }}>
              <Text style={styles.companyName}>{companyProfile.ownerName}</Text>
              <Text style={styles.companyName}>{companyProfile.companyName}</Text>
              <Text style={styles.companyLabel}>📞 {companyProfile.phone}</Text>
              <Text style={styles.companyLabel}>📌 {companyProfile.address}</Text>


              
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
    backgroundColor: "#20dfb6ff",
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
  tapText: { color: "#007bff", marginTop: 10 },
  nameLabel: { fontSize: 18, color: "#4b656fff", textAlign: "center" },
  nameText: { fontSize: 20, fontWeight: "bold", textAlign: "center", marginTop: 5 },
  companyLabel: { fontSize: 18, marginTop: 10, color: "#4b656fff", textAlign: "center" },
  companyName: { fontSize: 20, fontWeight: "700", textAlign: "center" },
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
  center: { justifyContent: "center", alignItems: "center" },
  input: {
    borderWidth: 1,
    borderColor: "#ccc",
    padding: 12,
    borderRadius: 10,
    marginBottom: 12,
    width: "100%",
  },
  saveBtn: {
    backgroundColor: "#20dfb6ff",
    padding: 12,
    borderRadius: 10,
    alignItems: "center",
  },
  saveText: { color: "white", fontSize: 16, fontWeight: "600" },
  cancelBtn: {
    marginTop: 10,
    padding: 10,
    alignItems: "center",
  },
  editBtn: {
    backgroundColor: "#20dfb6ff",
    padding: 12,
    borderRadius: 10,
    marginTop: 15,
  },
  editText: { color: "white", fontWeight: "600", fontSize: 16 },
});
