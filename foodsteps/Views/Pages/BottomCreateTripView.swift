//
//  BottomCreateTripView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 08/07/26.
//

import SwiftUI

struct BottomCreateTripView: View {
    // State variables untuk menyimpan input user
    @Binding var showDialog: Bool;
    @State private var tripName: String = ""
    @State private var tripDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600) // Default +1 jam
    
    // Custom Colors berdasarkan Hex yang diminta
    private let primaryColor = Color(hex: "4B08B5")
    private let borderColor = Color(hex: "#4B08B5")
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Header (X di kiri, Text di tengah)
            ZStack {
                HStack {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(primaryColor)
                        .onTapGesture {
                            showDialog = false
                        }
                    Spacer()
                }
                
                Text("Create Trip")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
            }
            .padding(.top, 32)
            .padding(.horizontal, 20)
            
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Trip Name Text Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trip Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryColor)
                        
                        TextField("Enter trip name...", text: $tripName)
                            .padding()
                            .foregroundColor(primaryColor)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(borderColor, lineWidth: 1.5)
                            )
                    }
                    
                    // MARK: - Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryColor)
                        
                        DatePicker("", selection: $tripDate, displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(borderColor, lineWidth: 1.5)
                            )
                    }
                    
                    // MARK: - Time Picker (From - To)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryColor)
                        
                        HStack(spacing: 12) {
                            // From Time
                            DatePicker("From", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(borderColor, lineWidth: 1.5)
                                )
                            
                            Text("to")
                                .foregroundColor(primaryColor)
                                .fontWeight(.medium)
                            
                            // To Time
                            DatePicker("To", selection: $endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(borderColor, lineWidth: 1.5)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meeting Point")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryColor)
                        
                        TextField("Enter trip name...", text: $tripName)
                            .padding()
                            .foregroundColor(primaryColor)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(borderColor, lineWidth: 1.5)
                            )
                    }
                    
                    // MARK: - Buttons (Full Width)
                    VStack(spacing: 12) {
                        // Button A (Primary Style)
                        Button(action: {
                            // Aksi Button A
                        }) {
                            Text("Save Trip")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#FF8F14"))
                                .cornerRadius(12)
                        }
                        
                        // Button B (Secondary / Bordered Style)
//                        Button(action: {
//                            // Aksi Button B
//                        }) {
//                            Text("Cancel")
//                                .fontWeight(.semibold)
//                                .foregroundColor(primaryColor)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .stroke(primaryColor, lineWidth: 2)
//                                )
//                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .ignoresSafeArea()
//        .padding(24)
        .contentMargins(.horizontal, 20)
        .background(Color(.systemBackground))
    }
}

#Preview {
//    BottomCreateTripView()
}
