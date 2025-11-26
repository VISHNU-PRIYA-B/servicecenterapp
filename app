import React, { useContext, useEffect } from "react";
import { NavigationContainer } from "@react-navigation/native";
import { createStackNavigator } from "@react-navigation/stack";
import { UserProvider, UserContext } from "./components/ui/UserContext";
import { setAuthToken } from "./services/api";

import Login from "./app/Login";
import Signup from "./app/Signup";
import CreateRepairRequest from "./app/CreateRepairRequest";
import AddEstimation from "./app/AddEstimation";
import ViewRequest from "./app/ViewRequest";
import ApproveEstimation from "./app/ApproveEstimation";
import AdminEstimation from "./app/AdminEstimation";
import UpdateStatus from "./app/UpdateStatus";
import Invoice from "./app/Invoice";

export type RootStackParamList = {
  Login: undefined;
  Signup: undefined;
  CreateRepairRequest: undefined;
  AddEstimation: undefined;
  ViewRequest: undefined;
  ApproveEstimation: undefined;
  AdminEstimation: undefined;
  UpdateStatus: undefined;
  Invoice: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();

function AppContent() {
  const { token } = useContext(UserContext);

  // Automatically apply token to Axios when user logs in or app loads
  useEffect(() => {
    setAuthToken(token);
  }, [token]);

  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="Login">
        <Stack.Screen
          name="Login"
          component={Login}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="Signup"
          component={Signup}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="CreateRepairRequest"
          component={CreateRepairRequest}
          options={{ title: "Repair Request" }}
        />
        <Stack.Screen
          name="AddEstimation"
          component={AddEstimation}
          options={{ title: "Add Estimation" }}
        />
        <Stack.Screen
          name="ViewRequest"
          component={ViewRequest}
          options={{ title: "View Request" }}
        />
        <Stack.Screen
          name="ApproveEstimation"
          component={ApproveEstimation}
          options={{ title: "Approve Estimation" }}
        />
          <Stack.Screen
          name="AdminEstimation"
          component={AdminEstimation}
          options={{ title: "Admin Estimation" }}
        />
        <Stack.Screen
          name="UpdateStatus"
          component={UpdateStatus}
          options={{ title: "Update Status" }}
        />
        <Stack.Screen
          name="Invoice"
          component={Invoice}
          options={{ title: "Invoice" }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default function App() {
  return (
    <UserProvider>
      <AppContent />
    </UserProvider>
  );
}
