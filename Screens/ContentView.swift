/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's top-level view that allows users to find music they want to rediscover.
*/

import MusicKit
import SwiftUI

struct ContentView: View {
    
    // MARK: - View
    
    var body: some View {
        rootView
            .onAppear(perform: recentAlbumsStorage.beginObservingMusicAuthorizationStatus)
            .onChange(of: searchTerm, perform: requestUpdatedSearchResults)
        
            // Display the barcode scanning view when appropriate.
        
            // Display the development settings view when appropriate.
            .sheet(isPresented: $isDevelopmentSettingsViewPresented) {
                DevelopmentSettingsView()
            }
        
            // Display the welcome view when appropriate.
            .welcomeSheet()
    }
    
    /// The various components of the main navigation view.
    private var navigationViewContents: some View {
        VStack {
            searchResultsList
                .animation(.default, value: albums)
        }
    }
    
    /// The top-level content view.
    private var rootView: some View {
        NavigationView {
            navigationViewContents
                .navigationTitle("Music Albums")
        }
        .searchable(text: $searchTerm, prompt: "Albums")
        .gesture(hiddenDevelopmentSettingsGesture)
    }
    
    // MARK: - Search results requesting
    
    /// The current search term the user enters.
    @State private var searchTerm = ""
    
    /// The albums the app loads using MusicKit that match the current search term.
    @State private var albums: MusicItemCollection<Album> = []
    
    /// A reference to the storage object for recent albums the user previously viewed in the app.
    @StateObject private var recentAlbumsStorage = RecentAlbumsStorage.shared
    
    /// A list of albums to display below the search bar.
    private var searchResultsList: some View {
        // 앨범이 비어있다 = 앨범 검색 결과가 없을 경우 최근 검색 기록 출력
        // 앨범이 있을 경우 검색 앨범 출력
        List(albums.isEmpty ? recentAlbumsStorage.recentlyViewedAlbums : albums) { album in
            AlbumCell(album) //
        }
    }
    
    /// Makes a new search request to MusicKit when the current search term changes.
    private func requestUpdatedSearchResults(for searchTerm: String) {
        Task {
            if searchTerm.isEmpty {
                self.reset() // 앨범 초기화
            } else { // 검색 진행
                do {
                    // Issue a catalog search request for albums matching the search term.
                    // MusicCatalogSearchRequest는 뮤직 리스트를 검색
                    // types : 검색 타입(앨범, 가수, 노래 등)
                    var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Album.self])
                    searchRequest.limit = 5
                    print(searchRequest)
                    let searchResponse = try await searchRequest.response()
                    print(searchResponse)
                    // Update the user interface with the search response.
                    self.apply(searchResponse, for: searchTerm)
                } catch {
                    print("Search request failed with error: \(error).")
                    self.reset()
                }
            }
        }
    }
    
    /// Safely updates the `albums` property on the main thread.
    @MainActor // @MainActor == 메인 스레드에서 호출
    private func apply(_ searchResponse: MusicCatalogSearchResponse, for searchTerm: String) {
        if self.searchTerm == searchTerm {
            self.albums = searchResponse.albums
        }
    }
    
    /// Safely resets the `albums` property on the main thread.
    @MainActor
    private func reset() {
        self.albums = []
    }
    
    // MARK: - Development settings
    
    /// `true` if the content view needs to display the development settings view.
    @State var isDevelopmentSettingsViewPresented = false
    
    /// A custom gesture that initiates the presentation of the development settings view.
    private var hiddenDevelopmentSettingsGesture: some Gesture {
        TapGesture(count: 3).onEnded {
            isDevelopmentSettingsViewPresented = true
        }
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
