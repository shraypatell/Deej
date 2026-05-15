//
//  PromoteEventView.swift
//  Sheet for announcing an upcoming event. Inserts a row into public.events
//  with promoted_by_user_id = self. New event appears on the Discover map.
//

import SwiftUI

struct PromoteEventView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var artistName: String = "@"
    @State private var venueName: String = ""
    @State private var city: String = "BKLYN"
    @State private var eventDate: Date = Date().addingTimeInterval(86_400 * 7) // a week out
    @State private var includeTime: Bool = false
    @State private var startTime: Date = {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        c.hour = 22
        c.minute = 0
        return Calendar.current.date(from: c) ?? .now
    }()
    @State private var isSubmitting: Bool = false

    private var isValid: Bool {
        artistName.trimmingCharacters(in: .whitespacesAndNewlines).count > 1 &&
        !venueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    field(label: "ARTIST", placeholder: "@artist_name", text: $artistName, autocapitalize: false)
                    field(label: "VENUE",  placeholder: "VENUE_NAME",   text: $venueName, autocapitalize: true)
                    field(label: "CITY",   placeholder: "BKLYN",        text: $city,      autocapitalize: true)
                    dateSection
                    timeSection
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            actionBar
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }

    // MARK: header
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Text("CANCEL")
                    .font(.deejMono(10, weight: .bold))
                    .foregroundStyle(.deejTextFaint)
                    .deejTracking(2)
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("PROMOTE")
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(.deejTextFaint)
                    .deejTracking(1.5)
                Text("NEW_EVENT")
                    .font(.deejMono(13, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(1)
            }
            Spacer()
            StatusLED(state: .pending, pulses: true)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.deejBgPanelEdge).frame(height: 1)
        }
    }

    // MARK: text field
    private func field(label: String, placeholder: String,
                       text: Binding<String>, autocapitalize: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            TextField("", text: text, prompt:
                Text(placeholder)
                    .font(.deejMono(13, weight: .semibold))
                    .foregroundStyle(.deejOrangeLow))
                .font(.deejMono(14, weight: .semibold))
                .foregroundStyle(.deejCream)
                .textInputAutocapitalization(autocapitalize ? .characters : .never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.deejButtonDark)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
                        }
                }
        }
    }

    // MARK: date
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EVENT_DATE")
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            HStack {
                DatePicker("", selection: $eventDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.deejOrangePrimary)
                    .colorScheme(.dark)
                Spacer()
            }
        }
    }

    // MARK: time
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("START_TIME")
                    .font(.deejMono(9, weight: .semibold))
                    .foregroundStyle(.deejCreamDim)
                    .deejTracking(1.5)
                Spacer()
                Toggle("", isOn: $includeTime)
                    .labelsHidden()
                    .tint(.deejOrangePrimary)
            }

            if includeTime {
                HStack {
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.deejOrangePrimary)
                        .colorScheme(.dark)
                    Spacer()
                }
            } else {
                Text("not specified · TBA")
                    .font(.deejMono(10))
                    .foregroundStyle(.deejOrangeLow)
            }
        }
    }

    // MARK: action bar
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button("CANCEL") { dismiss() }
                .buttonStyle(.hardware(.ghost))
                .font(.deejMono(13, weight: .bold))
                .deejTracking(2)
                .frame(height: 52)

            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView().tint(.deejBgScreen)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(isSubmitting ? "POSTING…" : "POST_TO_DEEJ")
                        .font(.deejMono(13, weight: .bold))
                        .deejTracking(2)
                }
            }
            .buttonStyle(.hardware(.primary))
            .disabled(!isValid || isSubmitting)
            .opacity(isValid && !isSubmitting ? 1 : 0.5)
            .frame(height: 52)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background {
            Color.deejBgPanel.ignoresSafeArea()
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.deejBgPanelEdge).frame(height: 1)
                }
        }
    }

    private func submit() async {
        guard isValid else { return }
        isSubmitting = true
        let artist = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        let venue  = venueName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cityValue = city.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        _ = await services.createEvent(
            artistName: artist,
            venueName: venue,
            city: cityValue,
            eventDate: eventDate,
            startTime: includeTime ? combineDateTime(eventDate, startTime) : nil
        )
        isSubmitting = false
        dismiss()
    }

    private func combineDateTime(_ date: Date, _ time: Date) -> Date {
        let cal = Calendar.current
        var dc = cal.dateComponents([.year, .month, .day], from: date)
        let tc = cal.dateComponents([.hour, .minute], from: time)
        dc.hour = tc.hour
        dc.minute = tc.minute
        return cal.date(from: dc) ?? date
    }
}

#Preview {
    PromoteEventView()
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
