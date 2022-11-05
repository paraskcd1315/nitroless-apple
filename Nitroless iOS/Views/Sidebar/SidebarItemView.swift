//
//  SidebarItemView.swift
//  Nitroless iOS
//
//  Created by Paras KCD on 2022-11-02.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImageWebPCoder

struct SidebarItemView: View {
    var repo: Repo
    var removeRepo: () -> Void
    var selectRepo: () -> Void
    var closeSidebar: () -> Void
    var selectedRepo: SelectedRepo?
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(.white)
                .frame(width: 3, height: selectedRepo == nil ? 0 : selectedRepo?.repo.url == repo.url ? 32 : 0 )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .offset(x: -7)
                .opacity(selectedRepo == nil ? 0 : selectedRepo?.repo.url == repo.url ? 1 : 0)
            
            Button {
                self.selectRepo()
                self.closeSidebar()
            } label: {
                let imgUrl = repo.url.appending(path: repo.repoData!.icon)
                HStack {
                    WebImage(url: imgUrl)
                        .resizable()
                        .placeholder {
                            ProgressView()
                        }
                        .frame(width: 48, height: 48)
                        .background(Color.theme.appBGColor)
                        .clipShape(RoundedRectangle(cornerRadius: selectedRepo == nil ? 99 : selectedRepo?.repo.url == repo.url ? 8 : 99, style: .continuous))
                }
            }
            .padding(0)
            .frame(width: 48, height: 48)
            .buttonStyle(.plain)
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: selectedRepo == nil && selectedRepo?.repo.url == repo.url ? 99 : selectedRepo?.repo.url == repo.url ? 8 : 99, style: .continuous))
            .contextMenu {
                let repoName = repo.repoData!.name
                Button {
                    UIPasteboard.general.url = repo.url
                } label: {
                    Label("Copy Repo's URL", systemImage: "doc.on.clipboard")
                }
                
                Button(role: .destructive) {
                    self.removeRepo()
                    print("Removed Repo - \(repoName)")
                } label: {
                    Label("Remove Repo", systemImage: "trash")
                }
                
                Divider()
                
                Button(role: .cancel) {
                } label: {
                    Label("Cancel", image: "trash")
                }
            }
            .offset(x: -8)
        }
        .animation(.spring(), value: self.selectedRepo != nil && selectedRepo?.repo.url == repo.url)
    }
}