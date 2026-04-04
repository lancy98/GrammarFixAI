//
//  ContentView.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//
import SwiftUI
import ServiceManagement
import FoundationModels

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var vm = ContentViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                providerToggle
                providerBadge
            }
            modePicker
            
            if vm.selectedProvider == .openAI {
                apiKeyRow
            }
            
            Text("Add your text below:")
                .foregroundStyle(.secondary)
            TextEditor(text: $vm.textInput)
                .padding(.vertical, 4)
                .scrollContentBackground(.hidden)
                .background(.quaternary)
                .frame(minHeight: 100)
            
            Button {
                Task { await vm.correct() }
            } label: {
                HStack(spacing: 7) {
                    if vm.isLoadingResult {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .tint(actionButtonForeground)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .imageScale(.small)
                    }
                    Text(vm.isLoadingResult
                         ? "Fixing…"
                         : "\(vm.selectedMode.rawValue) with \(vm.selectedProvider.rawValue)")
                    .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(actionButtonForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(actionButtonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .disabled(vm.isCorrectionButtonDisabled)
            
            Text("Result below:")
                .foregroundStyle(.secondary)
            
            TextEditor(text: vm.textOutput.isEmpty ? .constant("Corrected text will appear here…") : $vm.textOutput)
                .disabled(true)
                .padding(.vertical, 4)
                .foregroundColor(outputTextColor)
                .scrollContentBackground(.hidden)
                .background(outputBG)
                .frame(minHeight: 100)
            
            if let error = vm.errorMessage {
                errorBanner(error)
            }
            
            Divider()
            
            HStack {
                Button {
                    vm.copyToClipboard()
                } label: {
                    Label(vm.copiedToClipboard ? "Copied!" : "Copy Result",
                          systemImage: vm.copiedToClipboard ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(vm.copiedToClipboard ? Color(hex: "#34D399") : Color(hex: "#5B8DEF"))
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoadingResult || vm.textOutput.isEmpty)
                
                Spacer()
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .bold()
                        .foregroundStyle(.red)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Launch at login", isOn: $vm.launchAtLogin)
                Text("""
                Add GrammarFix app to the menu bar automatically \
                when you log in on your Mac.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onChange(of: vm.launchAtLogin) { _, newValue in
            vm.updateLaunchAtLogin(newValue)
        }
        .onAppear {
            vm.onAppear()
        }
    }
    
    // MARK: - Subviews
    
    private var apiKeyRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 11))
                .foregroundColor(apiKeyIconColor)
            
            Group {
                if vm.apiKeyMasked && !vm.openAPIKey.isEmpty {
                    Text(String(repeating: "•", count: min(vm.openAPIKey.count, 30)))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(apiKeyMaskedColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                } else {
                    TextField("Paste your OpenAI API key…", text: $vm.openAPIKey)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(apiKeyTextColor)
                        .textFieldStyle(.plain)
                        .onSubmit { vm.saveAPIKey() }
                }
            }
            
            Button {
                vm.toggleAPIKeyVisibility()
            } label: {
                Image(systemName: vm.apiKeyMasked ? "eye" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(apiKeyIconColor)
            }
            .buttonStyle(.plain)
            
            Button { vm.saveAPIKey() } label: {
                Text(vm.apiKeySaved ? "Saved ✓" : "Save")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(vm.apiKeySaved ? Color(hex: "#34D399") : Color(hex: "#60A5FA"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (vm.apiKeySaved ? Color(hex: "#34D399") : Color(hex: "#60A5FA")).opacity(0.12)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .disabled(vm.openAPIKey.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(apiKeyBackgroundColor)
    }
    
    private var outputBG: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(vm.textOutput.isEmpty ? outputBackgroundEmpty : outputBackgroundFilled)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(vm.textOutput.isEmpty ? outputBorderEmpty : outputBorderFilled,
                            lineWidth: 0.5)
            )
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
        }
        .font(.system(size: 11))
        .foregroundColor(Color(hex: "#F87171"))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#F87171").opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(GrammarMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.25)) { vm.selectedMode = mode }
                } label: {
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(vm.selectedMode == mode ? .white : Color.primary.opacity(0.4))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Group {
                                if vm.selectedMode == mode {
                                    LinearGradient(
                                        colors: [Color(hex: "#5B8DEF"), Color(hex: "#7C3AED")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                } else {
                                    Color.primary.opacity(0.06)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var providerToggle: some View {
        HStack(spacing: 0) {
            ForEach(AIProvider.allCases, id: \.self) { provider in
                Button {
                    withAnimation(.spring(response: 0.25)) { vm.selectedProvider = provider }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: provider.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(provider.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(vm.selectedProvider == provider ? .white : providerToggleInactiveText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Group {
                            if vm.selectedProvider == provider {
                                LinearGradient(
                                    colors: [Color(hex: "#5B8DEF"), Color(hex: "#7C3AED")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(providerToggleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(providerToggleBorder, lineWidth: 0.5))
    }
    
    @ViewBuilder
    private var providerBadge: some View {
        let color = vm.isProviderReady
        ? Color(hex: vm.selectedProvider.badgeColor)
        : Color(hex: "#F87171")
        let label = vm.isProviderReady ? vm.selectedProvider.badgeLabel : "Not Set"
        let icon  = vm.isProviderReady ? vm.selectedProvider.badgeIcon  : "exclamationmark.triangle"
        
        Label(label, systemImage: icon)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
    
    // MARK: - Theming
    
    private var isDark: Bool { colorScheme == .dark }
    
    private var actionButtonForeground: Color {
        vm.isCorrectionButtonDisabled
        ? (isDark ? Color.white.opacity(0.6) : Color.primary.opacity(0.6))
        : .white
    }
    
    private var actionButtonBackground: some View {
        Group {
            if vm.isCorrectionButtonDisabled {
                LinearGradient(colors: [disabledActionButtonBackground, disabledActionButtonBackground],
                               startPoint: .leading, endPoint: .trailing)
            } else {
                LinearGradient(colors: [Color(hex: "#5B8DEF"), Color(hex: "#7C3AED")],
                               startPoint: .leading, endPoint: .trailing)
            }
        }
    }
    
    private var disabledActionButtonBackground: Color {
        isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.08)
    }
    
    private var outputTextColor: Color {
        vm.isTextOutputEmpty
        ? .secondary
        : (isDark ? Color(hex: "#A7F3D0") : Color(hex: "#065F46"))
    }
    
    private var outputBackgroundEmpty: Color {
        isDark ? Color.white.opacity(0.03) : Color.black.opacity(0.04)
    }
    
    private var outputBackgroundFilled: Color {
        isDark ? Color(hex: "#064E3B").opacity(0.28) : Color(hex: "#A7F3D0").opacity(0.22)
    }
    
    private var outputBorderEmpty: Color {
        isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.08)
    }
    
    private var outputBorderFilled: Color {
        isDark ? Color(hex: "#34D399").opacity(0.22) : Color(hex: "#059669").opacity(0.35)
    }
    
    private var apiKeyIconColor: Color {
        isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.35)
    }
    
    private var apiKeyMaskedColor: Color {
        isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)
    }
    
    private var apiKeyTextColor: Color {
        isDark ? .white : .primary
    }
    
    private var apiKeyBackgroundColor: Color {
        isDark ? Color.white.opacity(0.025) : Color.black.opacity(0.04)
    }
    
    private var providerToggleBackground: Color {
        isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.06)
    }
    
    private var providerToggleBorder: Color {
        isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.12)
    }
    
    private var providerToggleInactiveText: Color {
        isDark ? Color.white.opacity(0.4) : Color.primary.opacity(0.6)
    }
}

#Preview {
    ContentView()
}
