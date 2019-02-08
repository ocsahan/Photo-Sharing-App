//
//  ViewController.swift
//  Bowntz
//
//  Created by Cagri Sahan on 3/12/18.
//  Copyright © 2018 Cagri Sahan. All rights reserved.
//

import UIKit

// Attribution: https://spin.atomicobject.com/2015/12/23/swift-uipageviewcontroller-tutorial/
class WelcomeScreenController: UIPageViewController {
    
    // MARK: Variables
    lazy var orderedViewControllers: [UIViewController] = {
        return [self.getViewControllerByIdentifier("One"),
                self.getViewControllerByIdentifier("Two"),
                self.getViewControllerByIdentifier("Three")]
    }()
    
    // MARK: Functions
    func getViewControllerByIdentifier(_ stepNumber: String) -> UIViewController {
        let storyboard = UIStoryboard(name: "Welcome", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "Step\(stepNumber)")
        return vc
    }
    
    func stylePageControl() {
        let pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [type(of: self)])
        
        pageControl.currentPageIndicatorTintColor = #colorLiteral(red: 0.2705882353, green: 0.2705882353, blue: 0.2745098039, alpha: 1)
        pageControl.pageIndicatorTintColor = UIColor.white
    }
    
    // MARK: Lifecycle
    // Attribution: https://stackoverflow.com/a/35230783
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for view in view.subviews{
            if view is UIScrollView{
                view.frame = UIScreen.main.bounds
            }else if view is UIPageControl{
                view.backgroundColor = UIColor.clear
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        stylePageControl()
    }
}

// MARK: Extensions
extension WelcomeScreenController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else { return nil }
        guard orderedViewControllers.count > previousIndex else { return nil }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        
        guard orderedViewControllersCount != nextIndex else { return nil }
        guard orderedViewControllersCount > nextIndex else { return nil }
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
                return 0
        }
        return firstViewControllerIndex
    }
}
