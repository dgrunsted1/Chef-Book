//
//  CookView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/30/24.
//

import SwiftUI
import AudioToolbox
import UserNotifications

// MARK: - CookView

struct CookView: View {
    @EnvironmentObject var network: Network
    @State var recipe: Recipe
    @State var is_made: Bool
    @State var is_favorite: Bool
    @State var newNoteText: String = ""
    @State var showNewNote: Bool = false
    @State var isLoadingDetail: Bool = false
    @State private var blurredIngredients: Set<Int> = []
    @State private var blurredDirections: Set<Int> = []
    @State private var timers: [Int: CookTimer] = [:]

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    init(recipe: Recipe) {
        _recipe = State(initialValue: recipe)
        _is_made = State(initialValue: recipe.made)
        _is_favorite = State(initialValue: recipe.favorite)
    }

    private var useSplitLayout: Bool {
        #if os(macOS)
        return true
        #else
        return horizontalSizeClass == .regular
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CookHeaderView(recipe: recipe)

                CookActionBar(
                    recipe: recipe,
                    is_made: $is_made,
                    is_favorite: $is_favorite,
                    network: network
                )
                .padding(.horizontal)
                .padding(.vertical, 12)

                if useSplitLayout {
                    GeometryReader { geo in
                        HStack(alignment: .top, spacing: 16) {
                            CookIngredientsPane(
                                ingredients: recipe.ingredients,
                                blurred: $blurredIngredients
                            )
                            .frame(width: geo.size.width * 2 / 5 - 8)

                            CookDirectionsPane(
                                directions: recipe.directions,
                                blurred: $blurredDirections,
                                timers: $timers,
                                recipeName: recipe.title,
                                recipeImageURL: recipe.image
                            )
                            .frame(width: geo.size.width * 3 / 5 - 8)
                        }
                        .padding(.horizontal)
                    }
                    .frame(minHeight: 400)
                } else {
                    GeometryReader { geo in
                        VStack(spacing: 16) {
                            CookIngredientsPane(
                                ingredients: recipe.ingredients,
                                blurred: $blurredIngredients
                            )
                            .frame(height: min(CGFloat(recipe.ingredients.count * 38 + 40), geo.size.height * 0.35))

                            CookDirectionsPane(
                                directions: recipe.directions,
                                blurred: $blurredDirections,
                                timers: $timers,
                                recipeName: recipe.title,
                                recipeImageURL: recipe.image
                            )
                            .frame(height: geo.size.height * 0.6)
                        }
                        .padding(.horizontal)
                    }
                    #if os(iOS)
                    .frame(height: UIScreen.main.bounds.height * 0.85)
                    #else
                    .frame(height: 600)
                    #endif
                }

                CookNotesSection(
                    recipe: $recipe,
                    newNoteText: $newNoteText,
                    showNewNote: $showNewNote,
                    network: network
                )
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
        .background(Color("BaseColor"))
        .overlay {
            if isLoadingDetail {
                ProgressView()
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            if !recipe.isDetailLoaded {
                isLoadingDetail = true
            }
            network.getRecipeDetail(urlId: recipe.url_id) { detail in
                isLoadingDetail = false
                if let detail = detail {
                    recipe = detail
                    is_made = detail.made
                    is_favorite = detail.favorite
                }
            }
        }
        .onDisappear {
            timers.values.forEach { $0.pause() }
        }
        .ignoresSafeArea(.container, edges: .top)
        #if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        #endif
    }
}

// MARK: - CookHeaderView

private struct CookHeaderView: View {
    let recipe: Recipe

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if !recipe.image.isEmpty {
                AsyncImage(url: URL(string: recipe.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(height: 280)
                            .clipped()
                    case .failure:
                        Color("Base200Color")
                            .frame(height: 280)
                    default:
                        ZStack {
                            Color("Base200Color")
                            ProgressView()
                        }
                        .frame(height: 280)
                    }
                }
            }

            // Gradient overlay — only covers bottom third
            VStack(spacing: 0) {
                Color.clear
                LinearGradient(
                    colors: [.clear, Color("BaseColor").opacity(0.8), Color("BaseColor")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
            }
            .frame(height: 280)

            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.title)
                    .bold()
                    .foregroundColor(Color("TextColor"))

                if !recipe.desc.isEmpty {
                    Text(recipe.desc)
                        .font(.subheadline)
                        .foregroundColor(Color("TextColor").opacity(0.8))
                }

                HStack(spacing: 12) {
                    if !recipe.author.isEmpty {
                        Label(recipe.author, systemImage: "person")
                            .font(.caption)
                    }
                    if recipe.time_in_seconds > 0 {
                        Label(Network.formatTime(recipe.time_in_seconds), systemImage: "clock")
                            .font(.caption)
                    } else if !recipe.time_display.isEmpty {
                        Label(recipe.time_display, systemImage: "clock")
                            .font(.caption)
                    }
                    if !recipe.servings.isEmpty {
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                            .font(.caption)
                    }
                }
                .foregroundColor(Color("TextColor").opacity(0.7))

                HStack(spacing: 8) {
                    if !recipe.category.isEmpty {
                        TagPill(text: recipe.category)
                    }
                    if !recipe.cuisine.isEmpty {
                        TagPill(text: recipe.cuisine)
                    }
                    if !recipe.country.isEmpty {
                        TagPill(text: recipe.country)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color("MyPrimaryColor").opacity(0.2))
            .foregroundColor(Color("TextColor"))
            .clipShape(Capsule())
    }
}

// MARK: - CookActionBar

private struct CookActionBar: View {
    let recipe: Recipe
    @Binding var is_made: Bool
    @Binding var is_favorite: Bool
    let network: Network

    var body: some View {
        HStack(spacing: 16) {
            if !recipe.link_to_original_web_page.isEmpty,
               let url = URL(string: recipe.link_to_original_web_page) {
                Link(destination: url) {
                    Label("Original", systemImage: "link")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("Base200Color"))
                        .clipShape(Capsule())
                }
                .foregroundColor(Color("TextColor"))
            }

            Spacer()

            HStack(spacing: 12) {
                Toggle("", isOn: $is_made)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: is_made) {
                        network.toggle_made(recipeId: recipe.id, value: is_made) { _ in }
                    }

                Image(systemName: is_made ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.title3)
                    .foregroundColor(is_made ? Color("MyPrimaryColor") : Color("NeutralColor"))

                Button {
                    is_favorite.toggle()
                    network.toggle_favorite(recipeId: recipe.id, value: is_favorite) { _ in }
                } label: {
                    Image(systemName: is_favorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(is_favorite ? Color("MyPrimaryColor") : Color("NeutralColor"))
                }
            }
        }
    }
}

// MARK: - CookIngredientsPane

private struct CookIngredientsPane: View {
    let ingredients: [Ingredient]
    @Binding var blurred: Set<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ingredients")
                .font(.headline)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                        IngredientRowView(
                            ingredient: ingredient,
                            isBlurred: blurred.contains(index)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if blurred.contains(index) {
                                    blurred.remove(index)
                                } else {
                                    blurred.insert(index)
                                }
                            }
                        }
                    }
                }
            }
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 6)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 6)
                }
            )
        }
    }
}

// MARK: - IngredientRowView

private struct IngredientRowView: View {
    let ingredient: Ingredient
    let isBlurred: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            if isBlurred {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
            Text(ingredient.toString())
                .strikethrough(isBlurred)
                .opacity(isBlurred ? 0.3 : 1.0)
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - CookDirectionsPane

private struct CookDirectionsPane: View {
    let directions: [String]
    @Binding var blurred: Set<Int>
    @Binding var timers: [Int: CookTimer]
    let recipeName: String
    let recipeImageURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Directions")
                .font(.headline)
                .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(directions.enumerated()), id: \.offset) { index, direction in
                        DirectionRowView(
                            index: index,
                            direction: direction,
                            isBlurred: blurred.contains(index),
                            timer: timers[index],
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if blurred.contains(index) {
                                        blurred.remove(index)
                                    } else {
                                        blurred.insert(index)
                                    }
                                }
                            },
                            onTimerStart: { parsed in
                                if timers[index] == nil {
                                    let snippet = String(direction.prefix(60))
                                    let t = CookTimer(
                                        totalSeconds: parsed.totalSeconds,
                                        displayLabel: parsed.displayLabel,
                                        stepNumber: index + 1,
                                        stepSnippet: snippet,
                                        recipeName: recipeName,
                                        recipeImageURL: recipeImageURL
                                    )
                                    timers[index] = t
                                    t.start()
                                }
                            }
                        )
                    }
                }
            }
            .mask(
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 6)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 6)
                }
            )
        }
    }
}

// MARK: - DirectionRowView

private struct DirectionRowView: View {
    let index: Int
    let direction: String
    let isBlurred: Bool
    let timer: CookTimer?
    let onTap: () -> Void
    let onTimerStart: (ParsedTimer) -> Void

    private var parsedTimers: [ParsedTimer] {
        TimerParser.parse(direction: direction)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                if isBlurred {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                Text("\(index + 1).")
                    .bold()
                    .foregroundColor(Color("MyPrimaryColor"))
                Text(direction)
                    .strikethrough(isBlurred)
                    .opacity(isBlurred ? 0.3 : 1.0)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // Timer buttons
            if !parsedTimers.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(parsedTimers.enumerated()), id: \.offset) { _, parsed in
                        if timer == nil {
                            Button {
                                onTimerStart(parsed)
                            } label: {
                                Label(parsed.displayLabel, systemImage: "timer")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color("MyPrimaryColor").opacity(0.15))
                                    .foregroundColor(Color("MyPrimaryColor"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Active timer display
            if let timer {
                CookTimerView(timer: timer)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

// MARK: - CookTimerView

private struct CookTimerView: View {
    @Bindable var timer: CookTimer

    var body: some View {
        HStack(spacing: 12) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color("NeutralColor").opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(
                        timer.isComplete ? Color.green : Color("MyPrimaryColor"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)

                if timer.isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text(timer.timeString)
                        .font(.system(size: 9, design: .monospaced))
                }
            }

            // Step label + time display
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.stepLabel)
                    .font(.caption)
                    .foregroundColor(Color("NeutralColor"))
                Text(timer.timeString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(timer.isComplete ? .green : Color("TextColor"))
            }

            if timer.isComplete {
                Text("Done!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .bold()
            }

            Spacer()

            // Controls
            if !timer.isComplete {
                Button {
                    if timer.isRunning {
                        timer.pause()
                    } else {
                        timer.start()
                    }
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .foregroundColor(Color("MyPrimaryColor"))
                }
            }

            Button {
                timer.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(Color("NeutralColor"))
            }
        }
        .padding(10)
        .background(Color("Base200Color").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - CookNotesSection

private struct CookNotesSection: View {
    @Binding var recipe: Recipe
    @Binding var newNoteText: String
    @Binding var showNewNote: Bool
    let network: Network
    @FocusState private var isNoteFocused: Bool
    @State private var editingIndex: Int? = nil
    @State private var editText: String = ""
    @FocusState private var isEditFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Button("Add Note") {
                    showNewNote.toggle()
                    if showNewNote {
                        isNoteFocused = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("MyPrimaryColor"))
                .foregroundColor(.black)
            }

            if showNewNote {
                HStack {
                    TextField("Add a note...", text: $newNoteText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isNoteFocused)
                        .onSubmit { saveNote() }
                    Button("Save") { saveNote() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("MyPrimaryColor"))
                    .foregroundColor(.black)
                }
            }

            ForEach(Array(recipe.notes.enumerated()), id: \.element.id) { index, note in
                if editingIndex == index {
                    HStack {
                        TextField("Edit note...", text: $editText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isEditFocused)
                            .onSubmit { finishEditing(at: index) }
                        Button {
                            finishEditing(at: index)
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("MyPrimaryColor"))
                        }
                        Button {
                            editingIndex = nil
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(Color("NeutralColor"))
                        }
                    }
                } else {
                    HStack {
                        Text(note.content)
                            .padding(.vertical, 2)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editText = note.content
                        editingIndex = index
                        isEditFocused = true
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }

    private func finishEditing(at index: Int) {
        guard !editText.isEmpty else { return }
        let noteId = recipe.notes[index].id
        let newContent = editText
        recipe.notes[index].content = newContent
        editingIndex = nil
        network.update_note(id: noteId, content: newContent) { _ in }
    }

    private func saveNote() {
        guard !newNoteText.isEmpty else { return }
        let noteText = newNoteText
        network.create_note(content: noteText, recipeId: recipe.id) { noteId in
            if let noteId {
                recipe.notes.append(RecipeNote(id: noteId, content: noteText))
                newNoteText = ""
                showNewNote = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CookView(recipe: Recipe.sampleData[0])
        .environmentObject(Network())
}
