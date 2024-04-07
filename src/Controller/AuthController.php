<?php

declare(strict_types=1);

namespace App\Controller;

use App\Dto\Api\UserDto;
use App\Dto\DtoFactory;
use App\Repository\UserRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use App\Entity\User;

class AuthController extends AbstractController
{
    #[Route('/api/register', name: 'api-register', methods: [Request::METHOD_POST])]
    public function register(
        Request $request,
        UserRepository $userRepository,
        DtoFactory $dtoFactory,
        JWTTokenManagerInterface $JWTManager,
        UserPasswordHasherInterface $passwordHasher,
    ): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        $dto = $dtoFactory->create(UserDto::class, $data);

        if ($errors = $dtoFactory->validate($dto)) {
            return new JsonResponse([
                'success' => false,
                'message' => 'Invalid data',
                'errors' => $errors
            ], Response::HTTP_BAD_REQUEST);
        }

        $user = (new User())
            ->setRoles(['ROLE_USER'])
            ->setFirstName($dto->getFirstName())
            ->setLastName($dto->getLastName())
            ->setEmail($dto->getEmail())
        ;

        $hashedPassword = $passwordHasher->hashPassword($user, $dto->getPassword());
        $user->setPassword($hashedPassword);

        $userRepository->save($user);

        return new JsonResponse([
            'success' => true,
            'message' => 'User created! Use /api/login_check for get auth token.'
        ], Response::HTTP_OK);
    }

    #[Route('/api/ping', name: 'api-ping')]
    public function ping(): Response
    {
        //TODO: we can delete this method, it is only for test
        return new JsonResponse([
            'ping' => 'pong'
        ], Response::HTTP_OK);
    }
}
