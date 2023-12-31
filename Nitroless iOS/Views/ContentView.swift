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
import TelegramStickersImport

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var repoMan: RepoManager
    @StateObject var headerViewModel: HeaderViewModel = HeaderViewModel()
    @State var urlToAdd: String = ""
    @State var showAddPrompt = false
    @State var urlInvalidError = false
    @State var toastShown = false
    @State var showDefaultReposMenu = false
    @State var urlToDelete: URL? = nil
    @State var showDeletePrompt = false
    @State var showRepoMenuPrompt = false
    @State private var offset: CGFloat = 0
    @State private var sidebarOpened: Bool = false
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    private var isPortrait : Bool { UIDevice.current.orientation.isPortrait }
    @State var repoMenu: RepoPages = .emotes
    @State private var isWhatsAppDone = true
    
    var body: some View {
        if idiom == .pad && horizontalSizeClass == .regular {
            ipadOSView()
        } else {
            iOSView()
        }
    }
    
    func toggleShowDefaultReposMenu() {
        self.showDefaultReposMenu.toggle()
    }
    
    func toggleShowAddPrompt() {
        self.showAddPrompt.toggle()
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
        case "open-community-repos":
            showDefaultReposMenu = true
        default:
            return;
        }
    }
    
    func ipadOSView() -> some View {
        NavigationStack {
            HStack {
                SidebariPadView(showAddPrompt: { toggleShowAddPrompt() })
                VStack {
                    HeaderiPadView()
                        .environmentObject(headerViewModel)
                    ScrollView {
                        if repoMan.selectedRepo == nil {
                            if headerViewModel.isAboutActive && !headerViewModel.isKeyboardSettingsActive {
                                AboutView()
                            } else if !headerViewModel.isAboutActive && headerViewModel.isKeyboardSettingsActive {
                                KeyboardSettingsView()
                            } else {
                                HomeView(toastShown: $toastShown)
                            }
                        } else {
                            RepoView(toastShown: $toastShown, repo: repoMan.selectedRepo!.repo, repoMenu: $repoMenu)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.theme.appBGColor)
        }
        .background(Color.theme.appBGColor)
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
        .onOpenURL(perform: handleUrl)
    }
    
    func iOSView() -> some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                SidebarView(showDefaultReposMenu: { toggleShowDefaultReposMenu() }, showAddPrompt: { toggleShowAddPrompt() }, closeSidebar: { sidebarOpened = false }, resetRepoMenu: { repoMenu = .emotes })
                ScrollView {
                    if repoMan.selectedRepo == nil {
                        HomeView(toastShown: $toastShown)
                    } else {
                        RepoView(toastShown: $toastShown, repo: repoMan.selectedRepo!.repo, repoMenu: $repoMenu)
                    }
                }
                .foregroundColor(Color.theme.textColor)
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.theme.appBGColor)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged({ value in
                            if value.translation.height > 0 {
                                 return
                            } else {
                                 return
                            }
                            if value.translation.width > 0 {
                                self.offset = value.translation.width
                            } else {
                                self.offset = 72 + value.translation.width
                            }
                        })
                        .onEnded({ value in
                            if value.translation.width > 0 {
                                if value.translation.width > 5 {
                                    sidebarOpened = true
                                }
                            } else {
                                sidebarOpened = false
                            }
                        })
                )
                .animation(.spring().speed(1.5), value: self.offset)
                .toolbar {
                    ToolbarItemGroup(placement: .principal) {
                        HStack {
                            MenuButton(state: $sidebarOpened, sizeDivide: 1.5)
                                .offset(x: 6)
                                .onChange(of: sidebarOpened) { _ in
                                    self.offset = sidebarOpened ? 72 : 0
                                }
                            
                            Spacer()
                            
                            banner()
                                .padding(.vertical, 5)
                                .offset(x: repoMan.selectedRepo == nil ? 4 : 6)
                            
                            Spacer()
                            
                            if repoMan.selectedRepo == nil {
                                HStack {
                                    NavigationLink {
                                        AboutView()
                                    } label: {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(Color.theme.textColor)
                                    }
                                    .buttonStyle(.plain)
                                    NavigationLink {
                                        KeyboardSettingsView()
                                    } label: {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundColor(Color.theme.textColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                            } else {
                                HStack {
                                    ShareLink(item: repoMan.selectedRepo!.repo.url, subject: Text(repoMan.selectedRepo!.repo.repoData!.name), message: Text("Check out this Awesome Repo")) {
                                        Image(systemName: "square.and.arrow.up.fill")
                                            .foregroundColor(Color.theme.textColor)
                                    }
                                    .buttonStyle(.plain)
                                    // MARK: - WhatsApp
                                    if repoMan.hasRepoStickers(repo: repoMan.selectedRepo!.repo) {
                                        Button {
                                            if repoMan.selectedRepo != nil {
                                                urlToDelete = repoMan.selectedRepo!.repo.url
                                                showRepoMenuPrompt = true
                                            }
                                        } label: {
                                            Image(systemName: "gearshape.fill")
                                                .foregroundColor(Color.theme.textColor)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            if repoMan.selectedRepo != nil {
                                                urlToDelete = repoMan.selectedRepo!.repo.url
                                                showDeletePrompt = true
                                            }
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(Color.theme.textColor)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                .toolbarBackground(Color.theme.appBGTertiaryColor, for: .navigationBar)
            }
            .sheet(isPresented: $showDefaultReposMenu) {
                AddDefaultRepos(isShown: $showDefaultReposMenu)
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
            .confirmationDialog("Are you sure you want to remove this Repo?", isPresented: $showDeletePrompt, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    repoMan.selectHome()
                    repoMan.removeRepo(repo: urlToDelete!)
                }
            }
            .confirmationDialog("What you want to do?", isPresented: $showRepoMenuPrompt, titleVisibility: .visible) {
                // MARK: - Telegram
                Button("Add Stickers to Telegram") {
                    let stickerSet = StickerSet(software: "com.llsc12.Nitroless", type: .image)
                    if repoMan.selectedRepo != nil && repoMan.selectedRepo!.repo.repoData != nil && repoMan.selectedRepo!.repo.repoData!.stickers != nil {
                        for sticker in repoMan.selectedRepo!.repo.repoData!.stickers! {
                            let imageURLString = repoMan.selectedRepo!.repo.url
                                .appending(path: repoMan.selectedRepo!.repo.repoData!.stickerPath!)
                                .appending(path: sticker.name)
                                .appendingPathExtension(sticker.type).absoluteString
                            let imageCache: SDImageCache = SDImageCache.shared
                            let filepath = URL(filePath: imageCache.diskCache.cachePath(forKey: imageURLString)!)
                            if let data = try? Data(contentsOf: filepath) {
                                if let image = UIImage(data: data) {
                                    if let stickerData = Sticker.StickerData(image: image) {
                                        try? stickerSet.addSticker(data: stickerData, emojis: ["😎"])
                                    }
                                }
                            }
                        }
                        try? stickerSet.import()
                    }
                    
                }
                // MARK: - WhatsApp
                Button("Add Stickers to WhatsApp") {
                    isWhatsAppDone = false
                    Task {
                        do {
                            if repoMan.selectedRepo != nil {
                                try await repoMan.addToWhatsApp(repo: repoMan.selectedRepo!.repo)
                                isWhatsAppDone = true
                                if isWhatsAppDone {
                                    UIApplication.shared.open(URL(string: "whatsapp://stickerPack")!, options: [:], completionHandler: nil)
                                }
                            }
                        } catch {
                            print("WhatsApp Error")
                            isWhatsAppDone = true
                        }
                    }
                }
                .disabled(!isWhatsAppDone)
                
                Button("Remove Repo", role: .destructive) {
                    repoMan.selectHome()
                    repoMan.removeRepo(repo: urlToDelete!)
                }
            }
            .onOpenURL(perform: handleUrl)
        }
        .toast(isPresenting: $toastShown) {
            AlertToast(displayMode: .hud, type: .systemImage("checkmark", Color.theme.appSuccessColor), title: "Copied!", style: AlertToast.AlertStyle.style(backgroundColor: Color.theme.appBGTertiaryColor, titleColor: .white))
        }
    }
}

struct banner: View {
    
    @Environment(\.colorScheme) var cs
    
    var body: some View {
        HStack {
            if cs == .light {
                Image("bannerDark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image("banner")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}

struct MenuButton: View {
    @Binding var state: Bool
    var sizeDivide: CGFloat = 1
    
    var body: some View {
        Button {
            state.toggle()
        } label: {
            VStack(spacing: 8 / sizeDivide) {
                rect()
                    .rotationEffect(!state ? .degrees(0) : .degrees(45))
                    .offset(y: state ? 13 / sizeDivide : 0)
                rect()
                    .frame(width: state ? 20 / sizeDivide : 40 / sizeDivide)
                    .opacity(state ? 0 : 1)
                rect()
                    .rotationEffect(!state ? .degrees(0) : .degrees(-45))
                    .offset(y: state ? -13 / sizeDivide : 0)
            }
            .animation(.spring(), value: state)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func rect() -> some View {
        Rectangle()
            .fill(Color.theme.textColor)
            .frame(height: 5 / sizeDivide)
            .frame(maxWidth: 40 / sizeDivide)
            .cornerRadius(5 / sizeDivide)
    }
}
