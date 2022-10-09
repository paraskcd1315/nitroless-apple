//
//  ContentView.swift
//  Nitroless
//
//  Created by Lakhan Lothiyi on 29/09/2022.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImageWebPCoder
import AlertToast

struct ContentView: View {
    
    @EnvironmentObject var repoMan: RepoManager
    
    @State var urlToDelete: URL? = nil
    @State var showDeletePrompt = false
    
    @State var urlToAdd: String = ""
    @State var showAddPrompt = false
    @State var urlInvalidError = false
    
    @State var toastShown = false
    
    @State var showDefaultReposMenu = false
    
    @State var sheetDetent: PresentationDetent = .medium
    
    var body: some View {
        NavigationStack {
            List {
                Section("Repositories") {
                    if repoMan.repos.isEmpty {
                        Button {
                            showDefaultReposMenu = true
                        } label: {
                            Label("Add Community Repos", systemImage: "globe")
                        }
                    }
                    
                    ForEach(repoMan.repos, id: \.url) { repo in
                        repoButton(repo: repo)
                    }
                }
            }
            .refreshable {
                repoMan.reloadRepos()
            }
            .sheet(isPresented: $showDefaultReposMenu) {
                AddDefaultRepos(isShown: $showDefaultReposMenu, detent: $sheetDetent)
                    .presentationDetents([.fraction(0.3), .large], selection: $sheetDetent.animation(.easeInOut(duration: 0.2)))
            }
            .toolbar {
                HStack {
                    
                    Button {
                        showDefaultReposMenu = true
                    } label: {
                        Image(systemName: "globe")
                    }
                    
                    Spacer()
                    
                    Button {
                        showAddPrompt = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .navigationTitle("Nitroless")
            .confirmationDialog("Delete this broken repository?", isPresented: $showDeletePrompt, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    repoMan.removeRepo(repo: urlToDelete!)
                }
            }
            .alert("Add Repository", isPresented: $showAddPrompt) {
                TextField("Repository URL", text: $urlToAdd)
                
                Button("Add", role: .none) {
                    if let url = URL(string: urlToAdd) {
                        if repoMan.addRepo(repo: url.absoluteString) {} else {
                            urlInvalidError = true
                        }
                    } else {
                        urlInvalidError = true
                    }
                    
                    urlToAdd = ""
                }
                
                Button("Cancel", role: .cancel) {urlToAdd = ""}
            } message: {
                Text("Please enter the URL of a Nitroless Repository")
            }
            .alert("Invalid URL", isPresented: $urlInvalidError) {
                Button("Dismiss", role: .cancel) {}
            } message: {
                Text("Please check the URL and try again.")
            }
            .onOpenURL { url in
                handleUrl(url)
            }
            
        }
        .toast(isPresenting: $toastShown, alert: {
            AlertToast(displayMode: .hud, type: .systemImage("checkmark", .green), title: "Copied!")
        })
    }
    
    func handleUrl(_ url: URL) {
        var str = url.absoluteString
        str = str.replacingOccurrences(of: "nitroless://", with: "https://nitroless.github.io/")
        let comp = URLComponents(string: str)!
        let path = comp.path.dropFirst()
        
        switch path {
        case "add-repository":
            guard let urlparam = comp.queryItems?.filter({ item in item.name == "url"}).first else { return }
            guard let param = urlparam.value else { return }
            
            urlToAdd = param
            showAddPrompt = true
        default:
            return;
        }
    }
    
    @ViewBuilder
    func repoButton(repo: Repo) -> some View {
        if let data = repo.repoData {
            NavigationLink {
                RepoView(toastShown: $toastShown, repo: repo)
            } label: {
                let imgUrl = repo.url.appending(path: data.icon)
                WebImage(url: imgUrl)
                    .resizable()
                    .placeholder {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 30)
                    .clipShape(Circle())
                Text(data.name)
            }
            .swipeActions(allowsFullSwipe: true) {
                Button {
                    repoMan.removeRepo(repo: repo.url)
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.url = repo.url
                } label: {
                    Label("Copy URL", systemImage: "doc.on.clipboard")
                }
                Button {
                    repoMan.removeRepo(repo: repo.url)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } else {
            Button {
                urlToDelete = repo.url
                showDeletePrompt = true
            } label: {
                HStack {
                    Text(repo.url.absoluteString)
                    Spacer()
                    Image(systemName: "x.circle.fill")
                        .foregroundColor(.red)
                        .offset(x: 5)
                }
            }
            .swipeActions(allowsFullSwipe: true) {
                Button {
                    repoMan.removeRepo(repo: repo.url)
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
        }
    }
}