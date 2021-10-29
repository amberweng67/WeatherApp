//
//  SearchCityViewController.swift
//  WeatherApp
//
//  Created by Hanchi Zhang on 10/28/21.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftSpinner
import RealmSwift

class SearchCityViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tblView: UITableView!
    
    var cityInfoList: [CityInfo] = [CityInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count < 3 {
            return
        }
        cityInfoList.removeAll()
        getCitiesFromSearch(searchText)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityInfoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let cityInfo = cityInfoList[indexPath.row]
        let text = "\(cityInfo.localizedName) \(cityInfo.administrativeId), \(cityInfo.countryLocalizedName)"
        cell.textLabel?.text = text
        return cell
    }
    
    func getSearchUrl(_ searchText: String) -> String{
        return "\(locationSearchUrl)?apikey=\(apiKey)&q=\(searchText)"
    }
    
    func getCitiesFromSearch(_ searchText: String) {
        let url = getSearchUrl(searchText)
        AF.request(url).responseJSON { response in
            if response.error != nil {
                print(response.error?.localizedDescription)
            }
            
            if response.data == nil {
                return
            }
            let cities = JSON(response.data)
            for (_, city):(String, JSON) in cities {
                let cityInfo = CityInfo()
                cityInfo.key = city["Key"].stringValue
                cityInfo.administrativeId = city["AdministrativeArea"]["ID"].stringValue
                cityInfo.countryLocalizedName = city["Country"]["LocalizedName"].stringValue
                cityInfo.localizedName = city["LocalizedName"].stringValue
                cityInfo.type = city["Type"].stringValue
                self.cityInfoList.append(cityInfo)
            }
            self.tblView.reloadData()
        }
    }
    
    func doesCityExistInDB(_ cityKey : String) -> Bool {
        do{
            let realm = try Realm()
            if realm.object(ofType: CityInfo.self, forPrimaryKey: cityKey) != nil { return true }
                
            }catch{
                print("Error in getting values from DB \(error)")
            }
            return false
        }
    
    func addCityinDB(_ cityInfo : CityInfo){
        do{
            let realm = try Realm()
            try realm.write {
                realm.add(cityInfo, update: .modified)
            }
        }catch{
            print("Error in inserting values into DB \(error)")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cityInfo = cityInfoList[indexPath.row]
        if !doesCityExistInDB(cityInfo.key) {
            addCityinDB(cityInfo)
        }
        
        self.navigationController?.popViewController(animated: true)
    }
}
