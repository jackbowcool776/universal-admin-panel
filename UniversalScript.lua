-- Test script to find what's breaking
task.wait(2)
print("Step 1 - basic wait works")

local Players = game:GetService("Players")
print("Step 2 - Players works")

local LocalPlayer = Players.LocalPlayer
print("Step 3 - LocalPlayer works")

local HttpService = game:GetService("HttpService")
print("Step 4 - HttpService works")

local TweenService = game:GetService("TweenService")
print("Step 5 - TweenService works")

local RunService = game:GetService("RunService")
print("Step 6 - RunService works")

local UserInputService = game:GetService("UserInputService")
print("Step 7 - UserInputService works")

local Lighting = game:GetService("Lighting")
print("Step 8 - Lighting works")

local StarterGui = game:GetService("StarterGui")
print("Step 9 - StarterGui works")

local Camera = workspace.CurrentCamera
print("Step 10 - Camera works")

print("All services loaded OK - script should work!")
