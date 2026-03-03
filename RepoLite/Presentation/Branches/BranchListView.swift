//
//  BranchListView.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import SwiftUI

public struct BranchListView: View {
    @ObservedObject var viewModel: BranchListViewModel

    public var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView(message: "Loading branches…")

            case .error(let msg):
                ErrorView(message: msg) {
                    Task { await viewModel.refresh() }
                }

            case .empty where viewModel.searchText.isEmpty:
                EmptyStateView(icon: "arrow.triangle.branch", title: "No Branches", subtitle: "This repository has no branches.")

            case .empty:
                EmptyStateView(icon: "magnifyingglass", title: "No Results", subtitle: "No branches match \"\(viewModel.searchText)\"")

            default:
                branchList
            }
        }
        .navigationTitle(viewModel.repository.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search branches")
        .onAppear { viewModel.onAppear() }
        .refreshable { await viewModel.refresh() }
    }

    private var branchList: some View {
        List {
            Section {
                repositoryHeader
            }

            Section("Branches (\(viewModel.filteredBranches.count))") {
                ForEach(viewModel.filteredBranches) { branch in
                    BranchRowView(branch: branch, isDefault: branch.name == viewModel.repository.defaultBranch)
                        .onAppear { viewModel.loadNextIfNeeded(current: branch) }
                }
            }

            if viewModel.viewState == .loadingMore {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowSeparator(.hidden)
            }
        }
    }

    private var repositoryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let desc = viewModel.repository.description {
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label("\(viewModel.repository.starCount)", systemImage: "star")
                Label("\(viewModel.repository.forksCount)", systemImage: "tuningfork")
                Label("\(viewModel.repository.openIssuesCount)", systemImage: "exclamationmark.circle")
                if let lang = viewModel.repository.language {
                    LanguageChip(language: lang)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct BranchRowView: View {
    let branch: Branch
    let isDefault: Bool

    var body: some View {
        HStack {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(.secondary)
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(branch.name)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)

                    if isDefault {
                        Text("default")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15), in: Capsule())
                            .foregroundStyle(.blue)
                    }

                    if branch.isProtected {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Protected branch")
                    }
                }

                Text(branch.commitSHA.prefix(7))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(branch.name)\(isDefault ? ", default" : "")\(branch.isProtected ? ", protected" : "")")
    }
}
