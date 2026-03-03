//
//  RepositoryListView.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import SwiftUI

public struct RepositoryListView: View {
    @ObservedObject var viewModel: RepositoryListViewModel
    @State private var showSignOutAlert = false
    let appContainer: AppContainer

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.viewState {
                case .loading:
                    LoadingView(message: "Loading repositories…")

                case .error(let msg):
                    ErrorView(message: msg) {
                        Task { await viewModel.refresh() }
                    }

                case .empty where viewModel.searchText.isEmpty:
                    EmptyStateView(
                        icon: "tray",
                        title: "No Repositories",
                        subtitle: "You don't have any repositories yet."
                    )

                case .empty:
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No Results",
                        subtitle: "No repositories match \"\(viewModel.searchText)\""
                    )

                default:
                    repositoryList
                }
            }
            .navigationTitle("Repositories")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $viewModel.searchText, prompt: "Search repositories")
            .toolbar { toolbarContent }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { viewModel.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear your session and return you to the sign-in screen.")
            }
            .onAppear { viewModel.onAppear() }
            .refreshable { await viewModel.refresh() }
        }
    }

    // MARK: - Repository List

    private var repositoryList: some View {
        List {
            ForEach(viewModel.filteredRepositories) { repo in
                NavigationLink {
                    BranchListView(
                        viewModel: appContainer.makeBranchListViewModel(repository: repo)
                    )
                } label: {
                    RepositoryRowView(repository: repo)
                }
                .onAppear { viewModel.loadNextPageIfNeeded(current: repo) }
            }

            if viewModel.viewState == .loadingMore {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(role: .destructive) {
                showSignOutAlert = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}

// MARK: - Repository Row

struct RepositoryRowView: View {
    let repository: Repository

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Name + privacy badge
                Text(repository.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if repository.isPrivate {
                    Label("Private", systemImage: "lock.fill")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let desc = repository.description {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                // Language chip
                if let lang = repository.language {
                    LanguageChip(language: lang)
                }

                // Stars
                Label("\(repository.starCount)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Spacer()

                // Last updated
                Text("Updated \(repository.updatedAt.relativeFormatted)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [repository.name]
        if repository.isPrivate { parts.append("private") }
        if let lang = repository.language { parts.append(lang) }
        parts.append("\(repository.starCount) stars")
        return parts.joined(separator: ", ")
    }
}
