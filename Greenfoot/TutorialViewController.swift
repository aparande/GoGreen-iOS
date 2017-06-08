//
//  TutorialViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/11/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class TutorialViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource, TutorialPageDelegate {

    var vcData:[[String:Any]]
    var currentViewController: TutorialPageViewController!
    
    init() {
        let titleSlide:[String: Any] = ["Title":"Welcome!", "Desc":"Welcome to Greenfoot! To start keeping track of your carbon footprint, enter some data. Any data you don't enter now can be entered later.", "Icon":Icon.logo_white]
        
        let electricSlide:[String: Any] = ["Title":"Electric", "Desc":"One of the largest contributions to climate change is due to our electricity usage. Find old electricity bills and enter your Kilowatt-Hour usage. It will be marked clearly near the amount due.", "Icon":Icon.electric_white]
        
        let waterSlide:[String: Any] = ["Title":"Water", "Desc":"Another large portion of our carbon footprint comes from our water usage. Find your old water bills and enter how many gallons you have used each month.", "Icon":Icon.water_white]
        let gasSlide:[String: Any] = ["Title":"Gas", "Desc":"Natural gas is a fossil fuel that we use directly. Although it is cleaner burning than coal and oil, methane is a greenhouse gas itself, and the combustion nevertheless produces carbon dioxide. Find your old gas bills and enter how much you have used each month.", "Icon":Icon.fire_white]
        
        let endSlide:[String: Any] = ["Title":"Ready?", "Desc":"You are now ready to use Greenfoot! Additional information you can enter to alter how many energy points you receive can be found on different pages. Make sure to update the data in the application each time you receive a new bill so we can help you keep track of your carbon footprint the best we can!", "Icon":Icon.logo_white]
        
        vcData = [titleSlide, electricSlide, waterSlide, gasSlide, endSlide]
        
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.delegate = self
        self.dataSource = self
        
        self.view.backgroundColor = Colors.green
        
        
        currentViewController = makeViewController(data: vcData[0])
        currentViewController.delegate = self
        
        setViewControllers([currentViewController], direction: .forward, animated: true, completion: nil)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = indexOf(vc: viewController)
        if index >= 0 && index+1 < vcData.count {
            return makeViewController(data: vcData[index+1])
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = indexOf(vc: viewController)
        if index > 0 && index-1 >= 0 {
            return makeViewController(data: vcData[index-1])
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        currentViewController = pendingViewControllers[0] as! TutorialPageViewController
        currentViewController.delegate = self
    }
    
    func makeViewController(data: [String: Any]) -> TutorialPageViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TutorialViewController") as! TutorialPageViewController
        if data["Title"] as! String == "Welcome!"  {
            vc.setValues(title: data["Title"] as! String, description: data["Desc"] as! String, icon: data["Icon"] as! UIImage, isEditable: false)
        } else if data["Title"] as! String == "Ready?" {
            vc.setValues(title: data["Title"] as! String, description: data["Desc"] as! String, icon: data["Icon"] as! UIImage, isEditable: false)
        } else {
            vc.setValues(title: data["Title"] as! String, description: data["Desc"] as! String, icon: data["Icon"] as! UIImage, isEditable: true)
        }
        
        return vc
    }
    
    func indexOf(vc: UIViewController) -> Int {
        if let viewController = vc as? TutorialPageViewController {
            let title = viewController.dataType
            for i in 0...vcData.count-1 {
                if vcData[i]["Title"] as? String == title {
                    return i
                }
            }
        }
        
        return -1
    }
    
    func skipPage() {
        if let viewController = pageViewController(self, viewControllerAfter: currentViewController) as? TutorialPageViewController {
            currentViewController = viewController
            currentViewController.delegate = self
            setViewControllers([currentViewController], direction: .forward, animated: true, completion: {
                completed in
            })
        } else {
            UserDefaults.standard.set(true, forKey: "CompletedTutorial")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            let svc = storyboard.instantiateViewController(withIdentifier: "Summary")
            let nvc = NavigationController(rootViewController: svc)
 
            let dvc = storyboard.instantiateViewController(withIdentifier: "Drawer")
            let ndvc = NavigationDrawerController(rootViewController: nvc, leftViewController: dvc, rightViewController: nil)
            self.present(ndvc, animated: true, completion: nil)
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return vcData.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return indexOf(vc: currentViewController)
    }
}
