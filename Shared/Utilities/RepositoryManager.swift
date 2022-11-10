//
//  RepositoryManager.swift
//  Nitroless
//
//  Created by Lakhan Lothiyi on 29/09/2022.
//

import Foundation

class RepoManager: ObservableObject {
    let fileManager = FileManager.default
    
    @Published var repos: [Repo]
    @Published var frequentlyUsed: [URL]
    @Published var favouriteEmotes: [URL]
    @Published var selectedRepo: SelectedRepo?
    @Published var selectedEmote: String?
    
    init() {
        self.repos = []
        self.frequentlyUsed = []
        self.favouriteEmotes = []
        self.loadRepos()
        self.loadFrequentEmotes()
        self.loadFavouriteEmotes()
    }
    
    public func selectRepo(selectedRepo: SelectedRepo) {
        self.selectedRepo = selectedRepo
    }
    
    public func selectHome() {
        self.selectedRepo = nil
    }
    
    public func hasRepositories() -> Bool {
        let repositories = StorageManager.shared.s.repos
        return !repositories.isEmpty
    }
    
    public func removeFromFavourite(repo: String, emote: String) {
        guard let repoUrl = URL(string: repo) else { return }
        guard let emoteUrl = URL(string: emote) else { return }
        let hostname = repoUrl.host
        let faveDict = StorageManager.shared.s.favouriteEmotesPerRepo
        
        if var repoFaves = faveDict[hostname!] {
            repoFaves = repoFaves.filter({ url in
                url != emoteUrl
            })
            
            StorageManager.shared.s.favouriteEmotesPerRepo[hostname!] = repoFaves
        }
        
        StorageManager.shared.s.frequentEmotes.removeAll(where: { url in
            url == emoteUrl
        })
    }
    
    public func removeRepo(repo: URL) {
        
        var repositories = StorageManager.shared.s.repos
        
        repositories = repositories.filter { loopedRepo in
            loopedRepo != repo
        }
        
        StorageManager.shared.s.repos = repositories
        
        DispatchQueue.main.async {
            self.repos = []
            self.loadRepos()
        }
    }
    
    public func addToFavourites(repo: String, emote: String) -> Void {
        var rep = repo
        let removeFromURL: Set<Character> = [".", "/"]
        if rep.prefix(8) == "https://" {
            rep.removeFirst(8)
        }
        rep.removeAll(where: {removeFromURL.contains($0)})
        
        guard let emoteURL = URL(string: emote) else {
            print("[AddToFavourites] Adding \"\(emote)\" failed, invalid URL")
            return
        }
        
        let file = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.llsc12.Nitroless")!.appendingPathComponent("Documents").appending(path: rep).appendingPathExtension("nitroless")
        
        let favouritesFile = FileLocations.favouriteEmotes
        
        if !fileManager.fileExists(atPath: file.path) {
            try? "".write(to: file, atomically: true, encoding: String.Encoding.utf8)
        }
        
        if !fileManager.fileExists(atPath: favouritesFile.path) {
            try? "".write(to: favouritesFile, atomically: true, encoding: String.Encoding.utf8)
        }

        let favEmotesString: String = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
        var favouriteEmotes = favEmotesString.components(separatedBy: "\n")
        
        if let e = favouriteEmotes.first {
            if e.isEmpty {
                favouriteEmotes = Array(favouriteEmotes.dropFirst())
            }
        }
        
        //Check if emote already exists
        for fe in favouriteEmotes {
            if emote == fe {
                let index = favouriteEmotes.firstIndex(of: fe)!
                favouriteEmotes.remove(at: index)
            }
        }
        
        favouriteEmotes.insert(emoteURL.absoluteString, at: 0)
        
        let final = favouriteEmotes.joined(separator: "\n")
        
        let favEmotesFileString: String = (try? String(contentsOf: favouritesFile, encoding: .utf8)) ?? ""
        var favouriteFileEmotes = favEmotesFileString.components(separatedBy: "\n")
        
        if let e = favouriteFileEmotes.first {
            if e.isEmpty {
                favouriteFileEmotes = Array(favouriteFileEmotes.dropFirst())
            }
        }
        
        //Check if emote already exists
        for fe in favouriteFileEmotes {
            if emote == fe {
                let index = favouriteFileEmotes.firstIndex(of: fe)!
                favouriteFileEmotes.remove(at: index)
            }
        }
        
        favouriteFileEmotes.insert(emoteURL.absoluteString, at: 0)
        
        let finalFavFile = favouriteFileEmotes.joined(separator: "\n")
        
        do {
            try final.write(to: file, atomically: true, encoding: String.Encoding.utf8)
            try finalFavFile.write(to: favouritesFile, atomically: true, encoding: String.Encoding.utf8)
            
            DispatchQueue.main.async {
                self.repos = []
                self.favouriteEmotes = []
                self.loadRepos()
                self.loadFavouriteEmotes()
            }
            return
        } catch {
            print("[AddToFavourites] Adding \"\(emote)\" failed, couldn't save to \(rep).nitroless file\n\(error)")
            return
        }
    }
    
    public func addToFrequentlyUsed(emote: String) -> Void {
        guard let emoteURL = URL(string: emote) else {
            print("[AddToFrequentlyUsed] Adding \"\(emote)\" failed, invalid URL")
            return
        }
        
        let file = FileLocations.frequentEmotes
        if !fileManager.fileExists(atPath: file.path) {
            try? "".write(to: file, atomically: true, encoding: String.Encoding.utf8)
        }
        
        let emotesString: String = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
        var emotes = emotesString.components(separatedBy: "\n")
        
        if let e = emotes.first {
            if e.isEmpty {
                emotes = Array(emotes.dropFirst())
            }
        }
        
        //Check if emote already exists
        for em in emotes {
            if emote == em {
                let index = emotes.firstIndex(of: em)!
                emotes.remove(at: index)
            }
        }
        
        emotes.insert(emoteURL.absoluteString, at: 0)
        
        //Check if frequently used emotes is above 50
        if emotes.count > 50 {
            emotes.removeLast()
        }
        
        let final = emotes.joined(separator: "\n")
        
        do {
            try final.write(to: file, atomically: true, encoding: String.Encoding.utf8)
            
            loadFrequentEmotes()
            return
        } catch {
            print("[AddToFrequentlyUsed] Adding \"\(emote)\" failed, couldn't save to frequentEmotes file\n\(error)")
            return
        }
    }
    
    public func addRepo(repo: String) -> Bool {
        
        guard let repoUrl = URL(string: repo) else {
            print("[AddRepo] Adding \"\(repo)\" failed, invalid url")
            return false
        }
        
        StorageManager.shared.s.repos.append(repoUrl)
        
        // get data and add to repo list
        let url = repoUrl
        let index = url.appending(path: "index.json")
        let req = URLRequest(url: index)
        
        
        URLSession.shared.dataTask(with: req) { [self] data, res, err in
            
            guard err == nil && "\((res as! HTTPURLResponse).statusCode)".hasPrefix("20") else {
                let repo = Repo(url: url, repoData: nil, favouriteEmotes: nil)
                DispatchQueue.main.async {
                    self.repos.append(repo)
                    self.reorderRepos()
                }
                return
            }
            
            guard let data = data else {
                let repo = Repo(url: url, repoData: nil, favouriteEmotes: nil)
                DispatchQueue.main.async {
                    self.repos.append(repo)
                    self.reorderRepos()
                }
                return
            }
            
            do {
                let json = try JSONDecoder().decode(NitrolessRepo.self, from: data)
                
                let final = Repo(url: url, repoData: json, favouriteEmotes: nil)
                
                DispatchQueue.main.async {
                    self.repos.append(final)
                    self.reorderRepos()
                }
            } catch {
                print(error)
                
                let repo = Repo(url: url, repoData: nil, favouriteEmotes: nil)
                DispatchQueue.main.async {
                    self.repos.append(repo)
                    self.reorderRepos()
                }
                return
            }
        }
        .resume()
            
        return true
    }
    
    public func reorderRepos() {
        self.repos.sort { r1, r2 in
            if let r1data = r1.repoData, let r2data = r2.repoData {
                return r1data.name.lowercased() < r2data.name.lowercased()
            } else {
                return r1.url.absoluteString.lowercased() < r2.url.absoluteString.lowercased()
            }
        }
    }
    
    private func loadFavouriteEmotes() {
        self.favouriteEmotes = []
        let file = FileLocations.favouriteEmotes
        
        if !fileManager.fileExists(atPath: file.path) {
            try? "".write(to: file, atomically: true, encoding: String.Encoding.utf8)
        }
        
        let emotesString = (try? String(contentsOf: file, encoding: .utf8))
        
        guard let emotesString = emotesString else { return }
        var emotes = emotesString.components(separatedBy: "\n")
        
        if let e = emotes.first {
            if e.isEmpty {
                emotes = Array(emotes.dropFirst())
            }
        }
        
        for emote in emotes {
            let url = URL(string: emote)!
            self.favouriteEmotes.append(url)
        }
    }
    
    private func loadFrequentEmotes() {
        self.frequentlyUsed = []
        self.frequentlyUsed = StorageManager.shared.s.frequentEmotes
    }
    
    private func loadRepos() {
        
        let repositories = StorageManager.shared.s.repos
                
        for repository in repositories {
            let url = repository
            let index = url.appending(path: "index.json")
            let req = URLRequest(url: index)
            var favouriteEmotes: [URL]?
            
            var rep = url.absoluteString
            let removeFromURL: Set<Character> = [".", "/"]
            if rep.prefix(8) == "https://" {
                rep.removeFirst(8)
            } else {
                rep.removeFirst(7)
            }
            rep.removeAll(where: {removeFromURL.contains($0)})
            
            let favEmotesFile = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.llsc12.Nitroless")!.appendingPathComponent("Documents").appending(path: rep).appendingPathExtension("nitroless")
            
            if fileManager.fileExists(atPath: favEmotesFile.path) {
                favouriteEmotes = []
                let favEmotesString: String = (try? String(contentsOf: favEmotesFile, encoding: .utf8)) ?? ""
                
                var favEmotes = favEmotesString.components(separatedBy: "\n")
                
                if let e = favEmotes.first {
                    if e.isEmpty {
                        favEmotes = Array(favEmotes.dropFirst())
                    }
                }
                
                for favEmote in favEmotes {
                    let url = URL(string: favEmote)
                    favouriteEmotes?.append(url!)
                }
            }
            
            URLSession.shared.dataTask(with: req) { [self] data, res, err in
                
                guard err == nil && "\((res as! HTTPURLResponse).statusCode)".hasPrefix("20") else {
                    let repo = Repo(url: url, repoData: nil, favouriteEmotes: nil)
                    DispatchQueue.main.async {
                        self.repos.append(repo)
                        self.reorderRepos()
                    }
                    return
                }
                
                guard let data = data else {
                    let repo = Repo(url: url, repoData: nil, favouriteEmotes: nil)
                    DispatchQueue.main.async {
                        self.repos.append(repo)
                        self.reorderRepos()
                    }
                    return
                }
                
                do {
                    let json = try JSONDecoder().decode(NitrolessRepo.self, from: data)
                    
                    let final = Repo(url: url, repoData: json, favouriteEmotes: favouriteEmotes)
                    
                    DispatchQueue.main.async {
                        self.repos.append(final)
                        self.reorderRepos()
                        
                        if self.selectedRepo != nil && self.selectedRepo!.repo.url == final.url {
                            self.selectedRepo = SelectedRepo(active: true, repo: final)
                        }
                    }
                } catch {
                    print(error)
                    
                    let repo = Repo(url: url, repoData: nil, favouriteEmotes: nil)
                    DispatchQueue.main.async {
                        self.repos.append(repo)
                        self.reorderRepos()
                    }
                    return
                }
            }
            .resume()
        }
    }
    
    public func getRepoData(url: URL) async throws -> Repo {
        let index = url.appending(path: "index.json")
        let req = URLRequest(url: index)
        let (data, _) = try await URLSession.shared.data(for: req)
        let repodata = try JSONDecoder().decode(NitrolessRepo.self, from: data)
        let repo = Repo(url: url, repoData: repodata, favouriteEmotes: nil)
        return repo
    }
    
    public func reloadRepos() {
        repos = []
        loadRepos()
    }
    
    public func reloadFrequentlyUsed() {
        loadFrequentEmotes()
    }
}

struct Repo {
    let url: URL
    let repoData: NitrolessRepo?
    let favouriteEmotes: [URL]?
}

struct SelectedRepo {
    let active: Bool
    let repo: Repo
}

// MARK: - NitrolessRepo
struct NitrolessRepo: Codable {
    let icon: String
    let author: String?
    let name, path: String
    let emotes: [NitrolessEmote]
}

// MARK: - NitrolessEmote
struct NitrolessEmote: Codable {
    let name, type: String
}

