function r = inscribed_sphere_radius(V)
% V is 3xN matrix of vertices

    % Compute convex hull (triangular facets)
    K = convhull(V(1,:)', V(2,:)', V(3,:)');

    r = inf;

    for i = 1:size(K,1)
        % Get three vertices of the facet
        p1 = V(:,K(i,1));
        p2 = V(:,K(i,2));
        p3 = V(:,K(i,3));

        % Compute plane normal
        n = cross(p2-p1, p3-p1);
        n = n / norm(n);   % normalize

        % Plane equation: n' * x = d
        d = abs(dot(n,p1));

        % Distance from origin to plane
        r = min(r, d);
    end
end
