import SwiftUI

struct ImageReflectionsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ReflectionsViewModel()
    @Binding var tabBarHiddenCount: Int

    private var tabClearance: CGFloat {
        _ = tabBarHiddenCount
        return TabMetrics.tabBarClearance
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    SectionHeaderView(
                        title: "Reflections",
                        subtitle: "Answer prompts to grow your journaling streak",
                        trailing: "\(store.reflectionStreakDays)d"
                    )

                    if viewModel.entries.isEmpty {
                        EmptyStateView(
                            symbol: "text.bubble",
                            title: "No reflections yet",
                            subtitle: "Answer prompts like “Why did this matter?” to grow your reflection streak."
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.entries) { entry in
                                Button {
                                    viewModel.open(entry)
                                } label: {
                                    MediaGridCell(
                                        emoji: entry.emoji,
                                        title: entry.title,
                                        subtitle: entry.prompt.isEmpty ? entry.tags.first : entry.prompt,
                                        highlighted: viewModel.pulseID == entry.id
                                    )
                                }
                                .buttonStyle(ScalePressStyle())
                                .contextMenu {
                                    Button("Edit") { viewModel.open(entry) }
                                    Button("Delete", role: .destructive) { viewModel.delete(entry) }
                                }
                            }
                        }

                        ForEach(viewModel.entries) { entry in
                            Button {
                                viewModel.open(entry)
                            } label: {
                                SurfaceCard {
                                    HStack(spacing: 12) {
                                        EmojiBadgeView(emoji: entry.emoji, size: 52)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(entry.title)
                                                .font(.headline)
                                                .foregroundStyle(Color("AppTextPrimary"))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            if !entry.prompt.isEmpty {
                                                Text(entry.prompt)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(Color("AppAccent"))
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                            }
                                            Text(entry.caption)
                                                .font(.caption)
                                                .foregroundStyle(Color("AppTextSecondary"))
                                                .lineLimit(2)
                                            TagChipRow(tags: entry.tags)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                            .buttonStyle(ScalePressStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, tabClearance + 80)
            }
            .clearScrollBackground()

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.openNew()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 56, height: 56)
                            .background(Color("AppPrimary"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(TabPressButtonStyle())
                    .padding(.trailing, 20)
                    .padding(.bottom, tabClearance)
                }
            }

            SuccessCheckOverlay(isVisible: viewModel.showSuccess)
        }
        .navigationTitle("Image Reflections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showEditor) {
            ReflectionEditorView(viewModel: viewModel)
                .environmentObject(store)
        }
    }
}

private struct TabPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ReflectionEditorView: View {
    @ObservedObject var viewModel: ReflectionsViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Reflection streak: \(store.reflectionStreakDays) day(s)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                            Spacer()
                        }

                        Text("Prompt")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(viewModel.selectedPrompt)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                viewModel.shufflePrompt()
                            } label: {
                                Label("Another prompt", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Color("AppPrimary").opacity(0.35))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(Color("AppSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("Your answer")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        TextEditor(text: $viewModel.captionText)
                            .frame(minHeight: 160)
                            .padding(10)
                            .scrollContentBackground(.hidden)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color("AppTextPrimary"))

                        MediaThumbnailView(emoji: viewModel.emoji, title: viewModel.titleText.isEmpty ? "Photo" : viewModel.titleText)
                            .frame(height: 180)

                        Text("Title")
                            .foregroundStyle(Color("AppTextSecondary"))
                        TextField("Reflection title", text: $viewModel.titleText)
                            .padding(14)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .modifier(ShakeEffect(animatableData: viewModel.titleShake))

                        if let validationMessage = viewModel.validationMessage {
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundStyle(Color.red.opacity(0.9))
                        }

                        Text("Visual")
                            .foregroundStyle(Color("AppTextSecondary"))
                        EmojiPickerView(selected: $viewModel.emoji)

                        Text("Tags (comma separated)")
                            .foregroundStyle(Color("AppTextSecondary"))
                        TextField("calm, evening, favorite", text: $viewModel.tagsText)
                            .padding(14)
                            .background(Color("AppSurface"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color("AppTextPrimary"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text(Date().formatted(date: .abbreviated, time: .shortened))
                                .foregroundStyle(Color("AppTextPrimary"))
                        }

                        Button {
                            viewModel.save()
                        } label: {
                            Text("Save Reflection")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Image Reflections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        FeedbackService.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
