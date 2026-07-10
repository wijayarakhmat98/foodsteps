import SwiftUI

/// The "edit trip schedule" sheet — a simple start/end date picker,
/// presented from the schedule row on the Places tab.
struct SchedulePickerSheetView: View {
    @Binding var draftStart: Date
    @Binding var draftEnd: Date

    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Starts", selection: $draftStart)
                DatePicker("Ends", selection: $draftEnd)
            }
            .navigationTitle("Trip Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
    }
}
