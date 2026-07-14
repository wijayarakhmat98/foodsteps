//
//  BottomCreateTripView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 08/07/26.
//

import SwiftUI
import MapKit

struct BottomCreateTripView: View {
    @ObservedObject var viewModel: TripHistoryViewModel
    
    @Binding var showDialog: Bool
    @State private var tripName: String = ""
    @State private var tripDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(3600)
    
    // State baru untuk Meeting Point
    @State private var meetingPoint: String = ""
    @State private var meetingPointCoordinate: CLLocationCoordinate2D? = nil
    @State private var meetingPointMapItem: MKMapItem?
    @State private var showMeetingPointSheet: Bool = false
    
    private let primaryColor = Color(hex: "4B08B5")
    private let borderColor = Color(hex: "#4B08B5")
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Header
            ZStack {
                HStack {
                    Button {
                        showDialog = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(primaryColor)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
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
                    // MARK: - Trip Name
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
                        ZStack(alignment: .leading) {
                            DatePicker("", selection: $tripDate, displayedComponents: .date)
                                .labelsHidden()
//                                .opacity(0.015)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(borderColor, lineWidth: 1.5)
                                )
                        }
                    }
                    
                    // MARK: - Time Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryColor)
                        HStack(spacing: 12) {
                            DatePicker("From", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1.5))
                            Text("to").foregroundColor(primaryColor).fontWeight(.medium)
                            DatePicker("To", selection: $endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1.5))
                        }
                    }
                    
                    // MARK: - Meeting Point (Dibuat Trigger Sheet)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meeting Point")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryColor)
                        
                        HStack {
                            Text(meetingPoint.isEmpty ? "Select meeting point..." : meetingPoint)
                                .foregroundColor(meetingPoint.isEmpty ? .gray : primaryColor)
                            Spacer()
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(primaryColor)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1.5)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showMeetingPointSheet = true
                        }
                    }
                    
                    // MARK: - Save Button
                    VStack(spacing: 12) {
                        Button(action: {
                            viewModel.createTrip(
                                name: tripName,
                                date: tripDate,
                                startTime: startTime,
                                endTime: endTime,
                                meetingPoint: meetingPoint,
                                coordinate: meetingPointCoordinate,
                                meetingPointMapItem: meetingPointMapItem
                            )
                            
                            showDialog = false
                        }) {
                            Text("Save Trip")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#FF8F14"))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 16)
                }
            }
        }
        .ignoresSafeArea()
        .contentMargins(.horizontal, 20)
        .background(Color(.systemBackground))
        // Menampilkan sheet .medium untuk pencarian lokasi
        .sheet(isPresented: $showMeetingPointSheet) {
            MeetingPointBottomView(
                selectedLocationName: $meetingPoint,
                selectedCoordinate: $meetingPointCoordinate,
                selectedMapItem: $meetingPointMapItem
            )
                .presentationDetents([.medium, .large]) // Membuka awal di .medium, bisa di-drag ke .large
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
//    @State var showDialog: Bool = true;
//
//    BottomCreateTripView(showDialog: $showDialog)
}
