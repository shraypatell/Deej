//
//  EventRankingView.swift
//  The signature screen — 7-dimension rating with rotary dial.
//

import SwiftUI

struct EventRankingView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var draft: RankingDraft
    var onLog: ((EventLog) -> Void)?

    init(event: Event, existing: EventLog? = nil, onLog: ((EventLog) -> Void)? = nil) {
        if let existing {
            _draft = State(initialValue: RankingDraft(event: event, existing: existing))
        } else {
            _draft = State(initialValue: RankingDraft(event: event))
        }
        self.onLog = onLog
    }

    var body: some View {
        @Bindable var draft = draft
        VStack(spacing: 0) {
            HardwarePanel {
                VStack(spacing: 0) {
                    topEngraving
                    crtSection
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    knobSection
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    Spacer()
                    bottomEngraving
                        .padding(.bottom, 12)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
    }

    // MARK: top device labels
    private var topEngraving: some View {
        HStack {
            Text("DEEJ.SYS")
            Spacer()
            Text("MOD-04 / RANK_EVENT")
            StatusLED(state: .ok, size: 5).padding(.leading, 6)
        }
        .font(.deejMono(9, weight: .medium))
        .foregroundStyle(Color.deejEngraving)
        .deejTracking(1.5)
        .padding(.horizontal, 20)
    }

    // MARK: CRT screen with event header + sliders
    private var crtSection: some View {
        CRTScreen {
            VStack(alignment: .leading, spacing: 8) {
                eventHeader.padding(.bottom, 4)
                dimensionsHeader
                Divider().overlay(Color.deejOrangeTrack)
                sliderColumn
            }
            .padding(14)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 420)
    }

    private var eventHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("EVENT // LOG_NEW")
                    .font(.deejMono(9, weight: .medium))
                    .foregroundStyle(Color.deejOrangeLow)
                    .deejTracking(1.2)
                Spacer()
                Text(currentTime)
                    .font(.deejMono(9, weight: .semibold))
                    .foregroundStyle(Color.deejCream)
                    .deejTracking(1.2)
            }
            Text(draft.event.artistName)
                .font(.deejMono(26, weight: .bold))
                .foregroundStyle(Color.deejCream)
                .deejTracking(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(metaLine)
                .font(.deejMono(10, weight: .medium))
                .foregroundStyle(Color.deejOrangeLow)
                .deejTracking(0.8)
        }
    }

    private var dimensionsHeader: some View {
        HStack {
            Text("DIMENSIONS · 7")
                .foregroundStyle(Color.deejOrangeLow)
            Spacer()
            Text("AGG ·")
                .foregroundStyle(Color.deejCreamDim)
            Text(draft.aggregateScore.formatted(.number.precision(.fractionLength(2))))
                .font(.deejMono(11, weight: .bold))
                .foregroundStyle(Color.deejOrangeHigh)
                .deejTracking(0.5)
                .contentTransition(.numericText(value: draft.aggregateScore))
                .animation(.snappy(duration: 0.2), value: draft.aggregateScore)
        }
        .font(.deejMono(9, weight: .semibold))
        .deejTracking(1.5)
    }

    private var sliderColumn: some View {
        VStack(spacing: 8) {
            ForEach(Dimension.rankingOrder, id: \.self) { dim in
                DimensionSlider(
                    label: dim.displayLabel,
                    value: draft.binding(for: dim),
                    isFocused: draft.focusedDimension == dim,
                    onFocus: { withAnimation(.snappy(duration: 0.2)) { draft.focusedDimension = dim } }
                )
            }
        }
    }

    // MARK: knob + actions
    private var knobSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 8) {
                RotaryKnob(value: draft.focusedBinding, size: 140)
                VStack(spacing: 2) {
                    Text("FOCUS · \(draft.focusedDimension.displayLabel)")
                        .font(.deejMono(8, weight: .semibold))
                        .foregroundStyle(Color.deejCreamDim)
                        .deejTracking(1.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("\(draft.value(for: draft.focusedDimension))")
                        .font(.deejMono(24, weight: .bold))
                        .foregroundStyle(Color.deejOrangeHigh)
                        .deejTracking(1)
                        .contentTransition(.numericText(value: Double(draft.value(for: draft.focusedDimension))))
                        .animation(.snappy(duration: 0.2),
                                   value: draft.value(for: draft.focusedDimension))
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                Button {
                    handleLog()
                } label: {
                    VStack(spacing: 2) {
                        Text("LOG")
                            .font(.deejMono(13, weight: .bold))
                            .deejTracking(2.5)
                        Text("EVENT")
                            .font(.deejMono(7, weight: .semibold))
                            .deejTracking(2)
                            .opacity(0.75)
                    }
                }
                .buttonStyle(.hardware(.primary))
                .frame(height: 60)

                Button {
                    dismiss()
                } label: {
                    Text("BACK")
                        .font(.deejMono(11, weight: .bold))
                        .deejTracking(2.5)
                }
                .buttonStyle(.hardware(.secondary))
                .frame(height: 44)

                Button {
                    resetCurrent()
                } label: {
                    Text("↶ UNDO")
                        .font(.deejMono(10, weight: .bold))
                        .deejTracking(2)
                }
                .buttonStyle(.hardware(.ghost))
                .frame(height: 44)
            }
            .frame(width: 104)
        }
    }

    private var bottomEngraving: some View {
        Text("PRECISION_AUDIO_LOG.CAP")
            .font(.deejMono(9, weight: .medium))
            .foregroundStyle(Color.deejEngraving)
            .deejTracking(2)
            .frame(maxWidth: .infinity)
    }

    // MARK: actions
    private func handleLog() {
        let log = draft.toEventLog(userId: services.userId)
        Task {
            await services.save(log)
            onLog?(log)
            dismiss()
        }
    }

    private func resetCurrent() {
        draft.setValue(5, for: draft.focusedDimension)
    }

    // MARK: helpers
    private var currentTime: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: .now)
    }

    private var metaLine: String {
        var parts: [String] = ["@ \(draft.event.venueName)"]
        if let city = draft.event.city { parts.append(city) }
        parts.append(eventDateString)
        return parts.joined(separator: " · ")
    }

    private var eventDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd · EEE"
        return f.string(from: draft.event.eventDate).uppercased()
    }
}

#Preview {
    let services = AppServices()
    let event = Event(
        id: UUID(), artistName: "@FOUR_TET", venueName: "KNOCKDOWN_CENTER",
        city: "BKLYN", eventDate: .now, startTime: nil, promotedByUserId: nil,
        createdAt: .now)
    return EventRankingView(event: event)
        .environment(services)
        .preferredColorScheme(.dark)
}
