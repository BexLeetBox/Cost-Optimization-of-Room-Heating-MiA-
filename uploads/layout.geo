// Auto-generated Gmsh geometry file
Point(1) = {450, 200, 0, 1.0};
Point(2) = {450, 350, 0, 1.0};
Point(3) = {650, 350, 0, 1.0};
Point(4) = {650, 500, 0, 1.0};
Point(5) = {750, 500, 0, 1.0};
Point(6) = {750, 350, 0, 1.0};
Point(7) = {750, 200, 0, 1.0};
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 5};
Line(5) = {5, 6};
Line(6) = {6, 7};
Line(7) = {7, 1};
Line Loop(8) = {1, 2, 3, 4, 5, 6, 7};
Plane Surface(9) = {8};